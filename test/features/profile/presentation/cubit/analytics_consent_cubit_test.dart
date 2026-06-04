import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';
import 'package:rideglory/core/services/user_storage_service.dart';
import 'package:rideglory/features/profile/presentation/cubits/analytics_consent_cubit.dart';

class MockUserStorageService extends Mock implements UserStorageService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockCrashReporter extends Mock implements CrashReporter {}

void main() {
  late MockUserStorageService storage;
  late MockAnalyticsService analytics;
  late MockCrashReporter crash;
  late AnalyticsConsentCubit cubit;

  setUp(() {
    storage = MockUserStorageService();
    analytics = MockAnalyticsService();
    crash = MockCrashReporter();
    when(() => analytics.setEnabled(any())).thenAnswer((_) async {});
    when(() => crash.setEnabled(any())).thenAnswer((_) async {});
    when(() => storage.setAnalyticsEnabled(any())).thenAnswer((_) async {});
    cubit = AnalyticsConsentCubit(storage, analytics, crash);
  });

  tearDown(() => cubit.close());

  group('AnalyticsConsentCubit', () {
    test('load() aplica la preferencia guardada a Analytics Y Crashlytics', () async {
      when(() => storage.getAnalyticsEnabled()).thenAnswer((_) async => true);

      await cubit.load();

      verify(() => analytics.setEnabled(true)).called(1);
      verify(() => crash.setEnabled(true)).called(1);
      expect(cubit.state, const ResultState<bool>.data(data: true));
    });

    test('load() con opt-out guardado (false) desactiva ambos', () async {
      when(() => storage.getAnalyticsEnabled()).thenAnswer((_) async => false);

      await cubit.load();

      verify(() => analytics.setEnabled(false)).called(1);
      verify(() => crash.setEnabled(false)).called(1);
      expect(cubit.state, const ResultState<bool>.data(data: false));
    });

    test('toggle(false) persiste y detiene Analytics + Crashlytics', () async {
      await cubit.toggle(false);

      verify(() => storage.setAnalyticsEnabled(false)).called(1);
      verify(() => analytics.setEnabled(false)).called(1);
      verify(() => crash.setEnabled(false)).called(1);
      expect(cubit.state, const ResultState<bool>.data(data: false));
    });

    test('toggle(true) reanuda Analytics + Crashlytics', () async {
      await cubit.toggle(true);

      verify(() => analytics.setEnabled(true)).called(1);
      verify(() => crash.setEnabled(true)).called(1);
      expect(cubit.state, const ResultState<bool>.data(data: true));
    });

    test('si la persistencia falla, revierte el switch y no cambia la colección',
        () async {
      when(() => storage.setAnalyticsEnabled(any()))
          .thenThrow(Exception('disk full'));

      await cubit.toggle(false);

      // Revierte al valor previo (true) tras el intento fallido de desactivar.
      expect(cubit.state, const ResultState<bool>.data(data: true));
      // No se tocó la colección porque la persistencia falló antes.
      verifyNever(() => analytics.setEnabled(any()));
      verifyNever(() => crash.setEnabled(any()));
    });
  });
}
