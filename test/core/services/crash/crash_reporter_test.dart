import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/services/crash/no_op_crash_reporter.dart';
import 'package:rideglory/core/services/crash/sentry_crash_reporter.dart';

void main() {
  group('NoOpCrashReporter', () {
    late NoOpCrashReporter reporter;

    setUp(() {
      reporter = NoOpCrashReporter();
    });

    test('TC-crash-1: recordError no lanza', () async {
      await expectLater(
        reporter.recordError(Exception('test'), null),
        completes,
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
    });

    test('TC-crash-3: recordError con fatal:true no lanza', () async {
      await expectLater(
        reporter.recordError(Exception('fatal'), null, fatal: true),
        completes,
      );
    });

    test('TC-crash-4: setEnabled(true) no lanza', () async {
      await expectLater(reporter.setEnabled(true), completes);
    });

    test('TC-crash-5: setEnabled(false) no lanza', () async {
      await expectLater(reporter.setEnabled(false), completes);
    });
  });

  group('SentryCrashReporter', () {
    test('TC-crash-6: setEnabled es no-op y no lanza', () async {
      final reporter = SentryCrashReporter();
      await expectLater(reporter.setEnabled(true), completes);
      await expectLater(reporter.setEnabled(false), completes);
    });
  });
}
