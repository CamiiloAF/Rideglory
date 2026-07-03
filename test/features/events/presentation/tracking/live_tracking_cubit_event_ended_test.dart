import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
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
import 'package:rideglory/core/domain/nothing.dart';

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
  late MockStopTrackingUseCase stopTrackingUseCase;
  late StreamController<void> eventEndedController;
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
    stopTrackingUseCase: stopTrackingUseCase,
    getRiderProfileUseCase: MockGetRiderProfileUseCase(),
    authService: MockAuthService(),
    trackingRepository: repo,
    analyticsService: analytics,
  );

  setUp(() {
    repo = MockTrackingRepository();
    analytics = MockAnalyticsService();
    stopTrackingUseCase = MockStopTrackingUseCase();
    eventEndedController = StreamController<void>.broadcast();
    sosAlertsController = StreamController<SosAlertModel>.broadcast();
    sosClearedController = StreamController<String>.broadcast();

    when(() => repo.eventEnded).thenAnswer((_) => eventEndedController.stream);
    when(() => repo.sosAlerts).thenAnswer((_) => sosAlertsController.stream);
    when(() => repo.sosCleared).thenAnswer((_) => sosClearedController.stream);
    when(() => analytics.logEvent(any())).thenAnswer((_) async {});
    when(() => analytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(
      () => stopTrackingUseCase(
        eventId: any(named: 'eventId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => const Right(Nothing()));

    cubit = buildCubit();
  });

  tearDown(() async {
    await cubit.close();
    await eventEndedController.close();
    await sosAlertsController.close();
    await sosClearedController.close();
  });

  group('LiveTrackingCubit — eventEnded cleanup', () {
    test('Caso A — path principal: stopUseCase llamado 1 vez, '
        'logEvent trackingSessionEnded 1 vez, '
        'estado isTracking=false, isFinished=true', () async {
      cubit.debugPrimeForEventEndedTest(userId);
      expect(cubit.state.isTracking, isTrue);

      eventEndedController.add(null);
      await Future<void>.delayed(Duration.zero);

      verify(
        () => stopTrackingUseCase(eventId: 'evt-1', userId: userId),
      ).called(1);
      verify(
        () => analytics.logEvent(AnalyticsEvents.trackingSessionEnded, {
          AnalyticsParams.trackingEndReason:
              AnalyticsParams.trackingEndReasonEventEnded,
        }),
      ).called(1);
      expect(cubit.state.isTracking, isFalse);
      expect(cubit.state.isFinished, isTrue);
    });

    test('Caso B — doble disparo: stopUseCase llamado 1 vez (no 2), '
        'logEvent trackingSessionEnded 1 vez (no 2)', () async {
      cubit.debugPrimeForEventEndedTest(userId);

      eventEndedController.add(null);
      await Future<void>.delayed(Duration.zero);

      // Segundo disparo — isTracking ya es false.
      eventEndedController.add(null);
      await Future<void>.delayed(Duration.zero);

      verify(
        () => stopTrackingUseCase(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      ).called(1);
      verify(
        () => analytics.logEvent(AnalyticsEvents.trackingSessionEnded, {
          AnalyticsParams.trackingEndReason:
              AnalyticsParams.trackingEndReasonEventEnded,
        }),
      ).called(1);
    });

    test(
      'Caso C — sin sesión activa: verifyNever stopUseCase, '
      'verifyNever logEvent trackingSessionEnded, estado isFinished=true',
      () async {
        cubit.debugSubscribeEventEndedForTest();
        expect(cubit.state.isTracking, isFalse);

        eventEndedController.add(null);
        await Future<void>.delayed(Duration.zero);

        verifyNever(
          () => stopTrackingUseCase(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          ),
        );
        verifyNever(
          () => analytics.logEvent(AnalyticsEvents.trackingSessionEnded, any()),
        );
        expect(cubit.state.isFinished, isTrue);
      },
    );

    test(
      'Caso D — use case retorna Left: cubit no lanza, '
      'estado isTracking=false, isFinished=true, stopUseCase llamado 1 vez',
      () async {
        when(
          () => stopTrackingUseCase(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(DomainException(message: 'err')));

        cubit.debugPrimeForEventEndedTest(userId);
        eventEndedController.add(null);
        await Future<void>.delayed(Duration.zero);

        verify(
          () => stopTrackingUseCase(
            eventId: any(named: 'eventId'),
            userId: any(named: 'userId'),
          ),
        ).called(1);
        expect(cubit.state.isTracking, isFalse);
        expect(cubit.state.isFinished, isTrue);
      },
    );
  });
}
