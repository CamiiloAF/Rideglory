import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
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

  // ── Fase 2: verificación de constantes AnalyticsEvents ───────────────────

  group('evento soat_scan_attempted —', () {
    test(
      'usa la constante AnalyticsEvents.soatScanAttempted (no literal)',
      () async {
        when(
          () => parseSoatText(any()),
        ).thenReturn(const SoatExtraction.empty());

        await expectLater(
          () => useCase(file: file, source: SoatScanSource.gallery),
          throwsA(isA<SoatScanException>()),
        );

        // Verifica la constante, no el string literal directamente.
        verify(
          () => analytics.logEvent(AnalyticsEvents.soatScanAttempted),
        ).called(1);
      },
    );
  });

  group('evento soat_scan_success —', () {
    setUp(() {
      when(() => parseSoatText(any())).thenReturn(
        const SoatExtraction(
          insurer: 'SURA',
          insurerConfidence: OcrFieldConfidence.high,
          policyNumber: '0123456789',
          policyNumberConfidence: OcrFieldConfidence.high,
        ),
      );
    });

    test(
      'usa la constante AnalyticsEvents.soatScanSuccess (no literal)',
      () async {
        await useCase(file: file, source: SoatScanSource.gallery);

        verify(
          () => analytics.logEvent(AnalyticsEvents.soatScanSuccess, any()),
        ).called(1);
      },
    );

    test(
      'insurer_detected es 1 (int) cuando hay aseguradora — no el nombre',
      () async {
        await useCase(file: file, source: SoatScanSource.gallery);

        final captured =
            verify(
                  () => analytics.logEvent(
                    AnalyticsEvents.soatScanSuccess,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, Object>;

        expect(
          captured[AnalyticsParams.insurerDetected],
          1,
          reason:
              'insurer_detected debe ser 1 cuando la aseguradora fue detectada',
        );
        expect(
          captured[AnalyticsParams.insurerDetected],
          isA<int>(),
          reason: 'insurer_detected debe ser int, no bool ni String',
        );
        // Aserción negativa: nunca debe llegar el nombre de la aseguradora.
        expect(
          captured.values.whereType<String>().any(
            (value) =>
                value.toUpperCase().contains('SURA') ||
                value.toUpperCase().contains('ASEGURADORA'),
          ),
          isFalse,
          reason: 'El nombre de la aseguradora NO debe viajar en el payload',
        );
      },
    );

    test('insurer_detected es 0 cuando no hay aseguradora', () async {
      when(() => parseSoatText(any())).thenReturn(
        const SoatExtraction(
          policyNumber: '0123456789',
          policyNumberConfidence: OcrFieldConfidence.high,
          // Sin campo insurer
          insurerConfidence: OcrFieldConfidence.high,
        ),
      );

      await useCase(file: file, source: SoatScanSource.gallery);

      final captured =
          verify(
                () => analytics.logEvent(
                  AnalyticsEvents.soatScanSuccess,
                  captureAny(),
                ),
              ).captured.single
              as Map<String, Object>;

      expect(captured[AnalyticsParams.insurerDetected], 0);
    });

    test('had_pdf es 1 para fuente PDF', () async {
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
                () => analytics.logEvent(
                  AnalyticsEvents.soatScanSuccess,
                  captureAny(),
                ),
              ).captured.single
              as Map<String, Object>;
      expect(captured[AnalyticsParams.hadPdf], 1);
      expect(captured[AnalyticsParams.hadPdf], isA<int>());
    });

    test('had_pdf es 0 para fuente imagen', () async {
      await useCase(file: file, source: SoatScanSource.camera);

      final captured =
          verify(
                () => analytics.logEvent(
                  AnalyticsEvents.soatScanSuccess,
                  captureAny(),
                ),
              ).captured.single
              as Map<String, Object>;
      expect(captured[AnalyticsParams.hadPdf], 0);
    });

    test('fields_extracted_count es int', () async {
      await useCase(file: file, source: SoatScanSource.gallery);

      final captured =
          verify(
                () => analytics.logEvent(
                  AnalyticsEvents.soatScanSuccess,
                  captureAny(),
                ),
              ).captured.single
              as Map<String, Object>;
      expect(captured[AnalyticsParams.fieldsExtractedCount], isA<int>());
    });
  });

  group('evento soat_scan_failed —', () {
    test(
      'usa constante AnalyticsEvents.soatScanFailed con failureReason key',
      () async {
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

        final captured =
            verify(
                  () => analytics.logEvent(
                    AnalyticsEvents.soatScanFailed,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, Object>;

        // Usa la clave de constante, no literal.
        expect(captured.containsKey(AnalyticsParams.failureReason), isTrue);
        expect(captured[AnalyticsParams.failureReason], 'validation_failed');
      },
    );

    test('emits validationFailed when dates failed the span rule', () async {
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
        () => analytics.logEvent(AnalyticsEvents.soatScanFailed, {
          AnalyticsParams.failureReason: 'validation_failed',
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
  });

  // ── Aserción negativa global: nunca un String de aseguradora en ningún
  // evento ────────────────────────────────────────────────────────────────────
  test(
    'ningún logEvent envía el nombre de la aseguradora como valor',
    () async {
      when(() => parseSoatText(any())).thenReturn(
        const SoatExtraction(
          insurer: 'SURA',
          insurerConfidence: OcrFieldConfidence.high,
          policyNumber: '0123456789',
          policyNumberConfidence: OcrFieldConfidence.high,
        ),
      );

      await useCase(file: file, source: SoatScanSource.gallery);

      final allCaptured = verify(
        () => analytics.logEvent(any(), captureAny()),
      ).captured;

      for (final params in allCaptured) {
        if (params is Map<String, Object>) {
          for (final value in params.values) {
            if (value is String) {
              expect(
                value.toUpperCase().contains('SURA'),
                isFalse,
                reason: 'El nombre de la aseguradora no debe viajar en eventos',
              );
            }
          }
        }
      }
    },
  );
}
