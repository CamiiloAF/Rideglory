import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/domain/model/sos_alert_model.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/start_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/stop_tracking_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_location_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/watch_active_riders_use_case.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';

class MockWatchActiveRidersUseCase extends Mock
    implements WatchActiveRidersUseCase {}

class MockStartTrackingUseCase extends Mock implements StartTrackingUseCase {}

class MockUpdateLocationUseCase extends Mock implements UpdateLocationUseCase {}

class MockStopTrackingUseCase extends Mock implements StopTrackingUseCase {}

class MockGetRiderProfileUseCase extends Mock
    implements GetRiderProfileUseCase {}

class MockAuthService extends Mock implements AuthService {}

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockTrackingRepository repo;
  late MockAnalyticsService analytics;
  late StreamController<SosAlertModel> sosAlertsController;
  late StreamController<String> sosClearedController;
  late LiveTrackingCubit cubit;

  const userId = 'rider-1';
  const ownerId = 'owner-1';

  LiveTrackingCubit buildCubit() => LiveTrackingCubit(
    eventId: 'evt-1',
    eventOwnerId: ownerId,
    watchActiveRidersUseCase: MockWatchActiveRidersUseCase(),
    startTrackingUseCase: MockStartTrackingUseCase(),
    updateLocationUseCase: MockUpdateLocationUseCase(),
    stopTrackingUseCase: MockStopTrackingUseCase(),
    getRiderProfileUseCase: MockGetRiderProfileUseCase(),
    authService: MockAuthService(),
    trackingRepository: repo,
    analyticsService: analytics,
  );

  setUp(() {
    repo = MockTrackingRepository();
    analytics = MockAnalyticsService();
    sosAlertsController = StreamController<SosAlertModel>.broadcast();
    sosClearedController = StreamController<String>.broadcast();

    when(() => repo.sosAlerts).thenAnswer((_) => sosAlertsController.stream);
    when(() => repo.sosCleared).thenAnswer((_) => sosClearedController.stream);
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});
    when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});

    cubit = buildCubit();
    // Deja la sesión lista para ejercitar SOS sin pasar por Geolocator.
    cubit.debugPrimeSosForTest(userId);
  });

  tearDown(() async {
    await cubit.close();
    await sosAlertsController.close();
    await sosClearedController.close();
  });

  group('LiveTrackingCubit — hitos de SOS (analytics)', () {
    test('triggerSos emite sos_activated exactamente 1 vez (role=rider) y '
        'ningún evento de ubicación/sesión', () {
      cubit.triggerSos();

      verify(
        () => analytics.logEvent(AnalyticsEvents.sosActivated, {
          AnalyticsParams.trackingRole: AnalyticsParams.trackingRoleRider,
        }),
      ).called(1);
      // Nunca hay un evento por ping de ubicación ni de arranque de sesión aquí.
      verifyNever(
        () => analytics.logEvent(AnalyticsEvents.trackingSessionStarted, any()),
      );
    });

    test('triggerSos + cancelSos emite sos_cleared (user_cancel) 1 vez', () {
      cubit.triggerSos();
      cubit.cancelSos();

      verify(
        () => analytics.logEvent(AnalyticsEvents.sosCleared, {
          AnalyticsParams.sosClearReason:
              AnalyticsParams.sosClearReasonUserCancel,
        }),
      ).called(1);
    });

    test('alerta de SOS propia emite sos_confirmed 1 vez', () async {
      sosAlertsController.add(
        const SosAlertModel(userId: userId, riderName: 'X'),
      );
      await Future<void>.delayed(Duration.zero);

      verify(() => analytics.logEvent(AnalyticsEvents.sosConfirmed)).called(1);
    });

    test('sos_confirmed NO se emite para alerta de otro rider', () async {
      sosAlertsController.add(
        const SosAlertModel(userId: 'otro', riderName: 'Y'),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => analytics.logEvent(AnalyticsEvents.sosConfirmed));
    });

    test(
      'clear remoto de mi SOS emite sos_cleared (remote_clear) 1 vez',
      () async {
        cubit.triggerSos(); // hasSentSos = true
        sosClearedController.add(userId);
        await Future<void>.delayed(Duration.zero);

        verify(
          () => analytics.logEvent(AnalyticsEvents.sosCleared, {
            AnalyticsParams.sosClearReason:
                AnalyticsParams.sosClearReasonRemoteClear,
          }),
        ).called(1);
      },
    );
  });
}
