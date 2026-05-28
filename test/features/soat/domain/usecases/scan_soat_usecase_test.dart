import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/ocr/ocr_result.dart';
import 'package:rideglory/core/services/ocr/ocr_service.dart';
import 'package:rideglory/features/soat/data/parser/soat_pdf_rasterizer.dart';
import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';
import 'package:rideglory/features/soat/domain/models/soat_scan_result.dart';
import 'package:rideglory/features/soat/domain/usecases/parse_soat_text_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/scan_soat_usecase.dart';

class MockOcrService extends Mock implements OcrService {}

class MockParseSoatTextUseCase extends Mock implements ParseSoatTextUseCase {}

class MockSoatPdfRasterizer extends Mock implements SoatPdfRasterizer {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeFile extends Fake implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(const OcrResult.empty());
  });

  late MockOcrService ocrService;
  late MockParseSoatTextUseCase parseSoatText;
  late MockSoatPdfRasterizer rasterizer;
  late MockAnalyticsService analytics;
  late ScanSoatUseCase useCase;

  final file = File('soat.jpg');
  const nonEmptyOcr = OcrResult(fullText: 'SEGUROS SURA', blocks: []);

  setUp(() {
    ocrService = MockOcrService();
    parseSoatText = MockParseSoatTextUseCase();
    rasterizer = MockSoatPdfRasterizer();
    analytics = MockAnalyticsService();
    useCase = ScanSoatUseCase(ocrService, parseSoatText, rasterizer, analytics);

    when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});
    when(
      () => ocrService.recognizeText(any()),
    ).thenAnswer((_) async => nonEmptyOcr);
  });

  test('emits validationFailed when dates failed the span rule', () async {
    // Two dates were found but failed the 360–370 day rule: not prefillable,
    // and the parser flags it so the use case can report validation_failed
    // instead of a generic low_confidence miss.
    when(
      () => parseSoatText(any()),
    ).thenReturn(const SoatExtraction(datesFailedValidation: true));

    await expectLater(
      () => useCase(file: file, source: SoatScanSource.gallery),
      throwsA(
        isA<SoatScanException>().having(
          (exception) => exception.reason,
          'reason',
          SoatScanFailureReason.validationFailed,
        ),
      ),
    );

    verify(
      () => analytics.logEvent('soat_scan_failed', {
        'failure_reason': 'validation_failed',
      }),
    ).called(1);
  });

  test(
    'emits lowConfidence when fields extracted but no date failure',
    () async {
      when(
        () => parseSoatText(any()),
      ).thenReturn(const SoatExtraction(insurer: 'SURA'));

      await expectLater(
        () => useCase(file: file, source: SoatScanSource.gallery),
        throwsA(
          isA<SoatScanException>().having(
            (exception) => exception.reason,
            'reason',
            SoatScanFailureReason.lowConfidence,
          ),
        ),
      );
    },
  );

  test('emits noTextDetected when nothing was extracted', () async {
    when(() => parseSoatText(any())).thenReturn(const SoatExtraction.empty());

    await expectLater(
      () => useCase(file: file, source: SoatScanSource.gallery),
      throwsA(
        isA<SoatScanException>().having(
          (exception) => exception.reason,
          'reason',
          SoatScanFailureReason.noTextDetected,
        ),
      ),
    );
  });

  test('logs had_pdf as int (1) on success for PDF source', () async {
    when(
      () => rasterizer.rasterizeFirstPage(any()),
    ).thenAnswer((_) async => file);
    when(() => parseSoatText(any())).thenReturn(
      const SoatExtraction(
        insurer: 'SURA',
        insurerConfidence: OcrFieldConfidence.high,
        policyNumber: '0123456789',
        policyNumberConfidence: OcrFieldConfidence.high,
      ),
    );

    final result = await useCase(file: file, source: SoatScanSource.pdf);

    expect(result, isA<SoatScanResult>());
    final captured =
        verify(
              () => analytics.logEvent('soat_scan_success', captureAny()),
            ).captured.single
            as Map<String, Object>;
    expect(captured['had_pdf'], 1);
    expect(captured['had_pdf'], isA<int>());
  });

  test('logs had_pdf as int (0) on success for image source', () async {
    when(() => parseSoatText(any())).thenReturn(
      const SoatExtraction(
        insurer: 'SURA',
        insurerConfidence: OcrFieldConfidence.high,
        policyNumber: '0123456789',
        policyNumberConfidence: OcrFieldConfidence.high,
      ),
    );

    await useCase(file: file, source: SoatScanSource.camera);

    final captured =
        verify(
              () => analytics.logEvent('soat_scan_success', captureAny()),
            ).captured.single
            as Map<String, Object>;
    expect(captured['had_pdf'], 0);
  });
}
