import 'dart:io';

import 'package:injectable/injectable.dart';

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
    await _analytics.logEvent('soat_scan_attempted');

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

    await _analytics.logEvent('soat_scan_success', {
      'fields_extracted_count': extraction.extractedFieldsCount,
      'insurer_detected': extraction.insurer ?? 'none',
      // Firebase Analytics drops bool params; send 0/1 so it reaches the
      // console.
      'had_pdf': source == SoatScanSource.pdf ? 1 : 0,
    });

    return SoatScanResult(extraction: extraction);
  }

  Future<void> _logFailure(SoatScanFailureReason reason) {
    return _analytics.logEvent('soat_scan_failed', {
      'failure_reason': reason.analyticsValue,
    });
  }
}
