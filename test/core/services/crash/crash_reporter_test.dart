import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';
import 'package:rideglory/core/services/crash/firebase_crash_reporter.dart';
import 'package:rideglory/core/services/crash/no_op_crash_reporter.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  group('NoOpCrashReporter', () {
    late NoOpCrashReporter reporter;
    // Spy SDK: verifica que NoOp NUNCA delega al SDK (verifyNever)
    late MockFirebaseCrashlytics spyCrashlytics;

    setUp(() {
      spyCrashlytics = MockFirebaseCrashlytics();
      reporter = NoOpCrashReporter();
    });

    test('TC-crash-1: recordError no lanza ni contacta Firebase', () async {
      await expectLater(
        reporter.recordError(Exception('test'), null),
        completes,
      );
      verifyNever(
        () => spyCrashlytics.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
        ),
      );
    });

    test('TC-crash-2: recordError con stack y reason no lanza', () async {
      final stack = StackTrace.current;
      await expectLater(
        reporter.recordError(
          Exception('error'),
          stack,
          reason: 'test reason',
          fatal: false,
        ),
        completes,
      );
      verifyNever(
        () => spyCrashlytics.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
        ),
      );
    });

    test('TC-crash-3: recordError con fatal:true no lanza', () async {
      await expectLater(
        reporter.recordError(Exception('fatal'), null, fatal: true),
        completes,
      );
      verifyNever(
        () => spyCrashlytics.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
        ),
      );
    });

    test('TC-crash-4: setEnabled(true) no lanza', () async {
      await expectLater(reporter.setEnabled(true), completes);
      verifyNever(
        () => spyCrashlytics.setCrashlyticsCollectionEnabled(any()),
      );
    });

    test('TC-crash-5: setEnabled(false) no lanza', () async {
      await expectLater(reporter.setEnabled(false), completes);
      verifyNever(
        () => spyCrashlytics.setCrashlyticsCollectionEnabled(any()),
      );
    });
  });

  group('FirebaseCrashReporter', () {
    late MockFirebaseCrashlytics mockCrashlytics;
    late CrashReporter reporter;

    setUp(() {
      mockCrashlytics = MockFirebaseCrashlytics();
      reporter = FirebaseCrashReporter(mockCrashlytics);
    });

    test('TC-crash-6: recordError delega al SDK con parámetros correctos',
        () async {
      final exception = Exception('sdk error');
      final stack = StackTrace.current;
      when(
        () => mockCrashlytics.recordError(
          exception,
          stack,
          reason: 'sdk reason',
          fatal: false,
        ),
      ).thenAnswer((_) async {});

      await reporter.recordError(
        exception,
        stack,
        reason: 'sdk reason',
        fatal: false,
      );

      verify(
        () => mockCrashlytics.recordError(
          exception,
          stack,
          reason: 'sdk reason',
          fatal: false,
        ),
      ).called(1);
    });

    test('TC-crash-7: recordError fatal:true delega al SDK correctamente',
        () async {
      final exception = Exception('fatal error');
      when(
        () => mockCrashlytics.recordError(
          exception,
          null,
          reason: any(named: 'reason'),
          fatal: true,
        ),
      ).thenAnswer((_) async {});

      await reporter.recordError(exception, null, fatal: true);

      verify(
        () => mockCrashlytics.recordError(
          exception,
          null,
          reason: any(named: 'reason'),
          fatal: true,
        ),
      ).called(1);
    });

    test('TC-crash-8: setEnabled delega a setCrashlyticsCollectionEnabled',
        () async {
      when(
        () => mockCrashlytics.setCrashlyticsCollectionEnabled(false),
      ).thenAnswer((_) async {});

      await reporter.setEnabled(false);

      verify(
        () => mockCrashlytics.setCrashlyticsCollectionEnabled(false),
      ).called(1);
    });

    test('TC-crash-9: setEnabled(true) delega al SDK', () async {
      when(
        () => mockCrashlytics.setCrashlyticsCollectionEnabled(true),
      ).thenAnswer((_) async {});

      await reporter.setEnabled(true);

      verify(
        () => mockCrashlytics.setCrashlyticsCollectionEnabled(true),
      ).called(1);
    });
  });
}
