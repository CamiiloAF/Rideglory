import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../../core/services/analytics/analytics_events.dart';
import '../../../../core/services/analytics/analytics_params.dart';
import '../../../../core/services/analytics/analytics_service.dart';
import '../../../../core/services/ocr/ocr_service.dart';
import '../../data/parser/soat_pdf_rasterizer.dart';
import '../models/soat_scan_result.dart';
import 'parse_soat_text_usecase.dart';

/// Orchestrates the full scan: (rasterize PDF →) OCR → parse → telemetry.
///
/// Throws [SoatScanException] with a machine-readable reason when the document
/// cannot be turned into a prefillable extraction. Telemetry events are
/// anonymous (no text, no images leave the device).
@injectable
class ScanSoatUseCase {
  const ScanSoatUseCase(
    this._ocrService,
    this._parseSoatText,
    this._pdfRasterizer,
    this._analytics,
  );

  final OcrService _ocrService;
  final ParseSoatTextUseCase _parseSoatText;
  final SoatPdfRasterizer _pdfRasterizer;
  final AnalyticsService _analytics;

  Future<SoatScanResult> call({
    required File file,
    required SoatScanSource source,
  }) async {
    await _analytics.logEvent(AnalyticsEvents.soatScanAttempted);

    File imageFile;
    try {
      imageFile = source == SoatScanSource.pdf
          ? await _pdfRasterizer.rasterizeFirstPage(file)
          : file;
    } catch (_) {
      await _logFailure(SoatScanFailureReason.unknownError);
      throw const SoatScanException(SoatScanFailureReason.unknownError);
    }

    final ocr = await _ocrService.recognizeText(imageFile);
    if (ocr.isEmpty) {
      await _logFailure(SoatScanFailureReason.noTextDetected);
      throw const SoatScanException(SoatScanFailureReason.noTextDetected);
    }

    final extraction = _parseSoatText(ocr);

    if (!extraction.shouldPrefill) {
      // Distinguish a date validation failure from generic low confidence so
      // the parser team can act on telemetry.
      final SoatScanFailureReason reason;
      if (extraction.datesFailedValidation) {
        reason = SoatScanFailureReason.validationFailed;
      } else if (extraction.extractedFieldsCount > 0) {
        reason = SoatScanFailureReason.lowConfidence;
      } else {
        reason = SoatScanFailureReason.noTextDetected;
      }
      await _logFailure(reason);
      throw SoatScanException(reason);
    }

    await _analytics.logEvent(AnalyticsEvents.soatScanSuccess, {
      AnalyticsParams.fieldsExtractedCount: extraction.extractedFieldsCount,
      // Privacidad: solo se envía si se detectó aseguradora (1) o no (0).
      // El nombre de la aseguradora es cuasi-PII / alta cardinalidad y NO
      // se envía. Decisión documentada en docs/features/analytics-taxonomy.md.
      AnalyticsParams.insurerDetected: extraction.insurer != null ? 1 : 0,
      // Firebase Analytics drops bool params; send 0/1 so it reaches the
      // console.
      AnalyticsParams.hadPdf: source == SoatScanSource.pdf ? 1 : 0,
    });

    return SoatScanResult(extraction: extraction);
  }

  Future<void> _logFailure(SoatScanFailureReason reason) {
    return _analytics.logEvent(AnalyticsEvents.soatScanFailed, {
      AnalyticsParams.failureReason: reason.analyticsValue,
    });
  }
}
