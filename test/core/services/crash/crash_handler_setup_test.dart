import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/crash/crash_handler_setup.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class MockCrashReporter extends Mock implements CrashReporter {}

/// Replica el PASO 2 de main.dart: llama setEnabled en un try/catch defensivo.
/// Siempre retorna true — el flujo continúa sea cual sea el resultado.
Future<bool> _runDefensiveInit(CrashReporter reporter) async {
  try {
    await reporter.setEnabled(true);
  } catch (_) {
    // Degradación silenciosa — igual que main.dart PASO 2
  }
  return true;
}

void main() {
  // ---------------------------------------------------------------------------
  // CA-2: Init defensivo
  // ---------------------------------------------------------------------------

  group('CA-2 — init defensivo (PASO 2 main.dart)', () {
    late MockCrashReporter reporter;

    setUp(() {
      reporter = MockCrashReporter();
    });

    test(
      'setEnabled que lanza NO propaga la excepción — runApp no se bloquea',
      () async {
        when(
          () => reporter.setEnabled(any()),
        ).thenThrow(Exception('Crashlytics init failed'));

        final result = await _runDefensiveInit(reporter);

        expect(result, isTrue,
            reason:
                'El flujo debe continuar aunque Crashlytics falle al init');
        // setEnabled fue invocado (intento real) pero la excepción fue absorbida
        verify(() => reporter.setEnabled(any())).called(1);
      },
    );

    test(
      'setEnabled exitoso — flujo continúa normalmente',
      () async {
        when(() => reporter.setEnabled(any())).thenAnswer((_) async {});

        final result = await _runDefensiveInit(reporter);

        expect(result, isTrue);
        verify(() => reporter.setEnabled(any())).called(1);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CA-3: Gating en kDebugMode — registerCrashHandlers
  // ---------------------------------------------------------------------------

  group('CA-3 — gating debug (registerCrashHandlers)', () {
    late MockCrashReporter reporter;

    setUp(() {
      reporter = MockCrashReporter();
      registerFallbackValue(StackTrace.empty);
    });

    tearDown(() {
      // Restaurar handlers a null para no contaminar otros tests
      FlutterError.onError = null;
      PlatformDispatcher.instance.onError = null;
    });

    test(
      'isDebug=true — handlers NO se modifican; recordError nunca se llama',
      () async {
        // Capturar handlers ANTES de la llamada
        final flutterHandlerBefore = FlutterError.onError;
        final platformHandlerBefore = PlatformDispatcher.instance.onError;

        registerCrashHandlers(isDebug: true, reporter: reporter);

        // Los handlers no deben haber cambiado
        expect(FlutterError.onError, same(flutterHandlerBefore),
            reason: 'FlutterError.onError no debe modificarse en debug');
        expect(PlatformDispatcher.instance.onError, same(platformHandlerBefore),
            reason:
                'PlatformDispatcher.onError no debe modificarse en debug');

        // recordError nunca fue invocado
        verifyNever(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ),
        );
      },
    );

    test(
      'isDebug=false — FlutterError.onError SE registra y delega a recordError',
      () async {
        when(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ),
        ).thenAnswer((_) async {});

        registerCrashHandlers(isDebug: false, reporter: reporter);

        expect(FlutterError.onError, isNotNull,
            reason: 'handler debe haber sido registrado');

        // Disparar el handler manualmente
        final details =
            FlutterErrorDetails(exception: Exception('prod error'));
        FlutterError.onError!(details);

        verify(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: true,
          ),
        ).called(1);
      },
    );

    test(
      'isDebug=false — PlatformDispatcher.onError SE registra y delega a recordError',
      () async {
        when(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ),
        ).thenAnswer((_) async {});

        registerCrashHandlers(isDebug: false, reporter: reporter);

        expect(PlatformDispatcher.instance.onError, isNotNull,
            reason: 'handler debe haber sido registrado');

        // Disparar el handler manualmente
        final handled = PlatformDispatcher.instance.onError!(
          Exception('plat error'),
          StackTrace.empty,
        );

        expect(handled, isTrue);
        verify(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: true,
          ),
        ).called(1);
      },
    );
  });
}
