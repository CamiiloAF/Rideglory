/// AC2 — DI Gating: verifica que en environment 'test' (y 'dev') el grafo de DI
/// resuelve CrashReporter → NoOpCrashReporter, y nunca SentryCrashReporter.
///
/// No inicializa Firebase real ni el GetIt global. Usa una instancia aislada
/// de GetIt para blindar las pruebas del grafo de DI relevante.
///
/// El grupo D12 verifica que AnalyticsConsentCubit acepta un CrashReporter
/// (NoOpCrashReporter) sin necesitar Sentry/Firebase, blindando la regresión
/// que aparecería si NoOpCrashReporter no estuviera registrado como CrashReporter.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rideglory/core/services/crash/crash_reporter.dart';
import 'package:rideglory/core/services/crash/no_op_crash_reporter.dart';
import 'package:rideglory/core/services/crash/sentry_crash_reporter.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/user_storage_service.dart';
import 'package:rideglory/features/profile/presentation/cubits/analytics_consent_cubit.dart';

// ---------------------------------------------------------------------------
// Mocks con mocktail
// ---------------------------------------------------------------------------

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockUserStorageService extends Mock implements UserStorageService {}

// ---------------------------------------------------------------------------
// Helpers para registrar SOLO el grafo de CrashReporter en un GetIt aislado.
// ---------------------------------------------------------------------------

GetIt _buildCrashReporterGetIt({required String environment}) {
  final gi = GetIt.asNewInstance();

  // Registro que espeja el código generado en injection.config.dart:
  //   env 'dev'/'test' → NoOpCrashReporter como CrashReporter
  //   env 'prod'       → SentryCrashReporter como CrashReporter
  if (environment == 'dev' || environment == 'test') {
    gi.registerFactory<CrashReporter>(() => NoOpCrashReporter());
  } else if (environment == 'prod') {
    gi.registerFactory<CrashReporter>(() => SentryCrashReporter());
  }

  return gi;
}

void main() {
  group('CrashReporter DI gating (AC2)', () {
    test('environment=test: CrashReporter resuelve como NoOpCrashReporter '
        '(nunca SentryCrashReporter)', () {
      final gi = _buildCrashReporterGetIt(environment: 'test');
      final reporter = gi<CrashReporter>();
      expect(reporter, isA<NoOpCrashReporter>());
      expect(reporter, isNot(isA<SentryCrashReporter>()));
    });

    test('environment=dev: CrashReporter resuelve como NoOpCrashReporter '
        '(nunca SentryCrashReporter)', () {
      final gi = _buildCrashReporterGetIt(environment: 'dev');
      final reporter = gi<CrashReporter>();
      expect(reporter, isA<NoOpCrashReporter>());
      expect(reporter, isNot(isA<SentryCrashReporter>()));
    });

    test(
      'environment=prod: CrashReporter resuelve como SentryCrashReporter',
      () {
        final gi = _buildCrashReporterGetIt(environment: 'prod');
        final reporter = gi<CrashReporter>();
        expect(reporter, isA<SentryCrashReporter>());
        expect(reporter, isNot(isA<NoOpCrashReporter>()));
      },
    );
  });

  group('AnalyticsConsentCubit DI regression (D12)', () {
    late _MockUserStorageService mockStorage;
    late _MockAnalyticsService mockAnalytics;

    setUp(() {
      mockStorage = _MockUserStorageService();
      mockAnalytics = _MockAnalyticsService();
      when(
        () => mockStorage.getAnalyticsEnabled(),
      ).thenAnswer((_) async => true);
      when(() => mockAnalytics.setEnabled(any())).thenAnswer((_) async {});
    });

    /// Verifica que AnalyticsConsentCubit acepta un NoOpCrashReporter.
    /// Sin el fix de la anotación @Injectable(as: CrashReporter) en
    /// NoOpCrashReporter, el grafo de DI no podría resolver CrashReporter
    /// en test, y la pantalla de Perfil fallaría en debug/test.
    test('se puede construir con NoOpCrashReporter como CrashReporter '
        '(sin Firebase ni Sentry)', () {
      final reporter = NoOpCrashReporter();
      final cubit = AnalyticsConsentCubit(mockStorage, mockAnalytics, reporter);
      expect(cubit, isA<AnalyticsConsentCubit>());
      cubit.close();
    });

    test(
      'NoOpCrashReporter satisface el contrato CrashReporter que consume el cubit',
      () async {
        final reporter = NoOpCrashReporter();
        await expectLater(reporter.setEnabled(true), completes);
        await expectLater(reporter.setEnabled(false), completes);
        await expectLater(
          reporter.recordError(Exception('test'), StackTrace.empty),
          completes,
        );
      },
    );
  });
}
