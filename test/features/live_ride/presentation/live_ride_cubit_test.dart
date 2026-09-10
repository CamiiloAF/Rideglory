import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/event.dart';
import 'package:rideglory/features/events/domain/event_difficulty.dart';
import 'package:rideglory/features/events/domain/event_state.dart';
import 'package:rideglory/features/events/domain/usecases/get_event_detail_use_case.dart';
import 'package:rideglory/features/live_ride/domain/background_tracking_service.dart';
import 'package:rideglory/features/live_ride/domain/live_ride_contacts_cache.dart';
import 'package:rideglory/features/live_ride/domain/live_rider.dart';
import 'package:rideglory/features/live_ride/domain/location_permission_state.dart';
import 'package:rideglory/features/live_ride/domain/location_service.dart';
import 'package:rideglory/features/live_ride/domain/usecases/get_location_permission_state_use_case.dart';
import 'package:rideglory/features/live_ride/domain/usecases/start_sharing_location_use_case.dart';
import 'package:rideglory/features/live_ride/domain/usecases/stop_sharing_location_use_case.dart';
import 'package:rideglory/features/live_ride/domain/usecases/watch_event_finished_use_case.dart';
import 'package:rideglory/features/live_ride/domain/usecases/watch_live_riders_use_case.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_cubit.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/live_ride_state.dart';
import 'package:rideglory/features/live_ride/presentation/cubit/sharing_status.dart';
import 'package:rideglory/features/live_ride/presentation/live_ride_route_args.dart';

class _MockWatchLiveRiders extends Mock implements WatchLiveRidersUseCase {}

class _MockWatchEventFinished extends Mock
    implements WatchEventFinishedUseCase {}

class _MockGetPermissionState extends Mock
    implements GetLocationPermissionStateUseCase {}

class _MockStartSharing extends Mock implements StartSharingLocationUseCase {}

class _MockStopSharing extends Mock implements StopSharingLocationUseCase {}

class _MockLocationService extends Mock implements LocationService {}

class _MockContactsCache extends Mock implements LiveRideContactsCache {}

class _MockBackgroundTrackingService extends Mock
    implements BackgroundTrackingService {}

class _MockGetEventDetail extends Mock implements GetEventDetailUseCase {}

Event _event() {
  return Event(
    id: 'event-1',
    ownerId: 'owner-1',
    ownerName: 'Juan Camilo',
    name: 'Rodada al Nevado del Ruiz',
    startAt: DateTime.utc(2026, 9, 10, 8),
    difficulty: EventDifficulty.easy,
    state: EventState.started,
    price: 0,
    approvedCount: 3,
    isOwnedByMe: false,
  );
}

LiveRider _rider() {
  return LiveRider(
    eventId: 'event-1',
    userId: 'user-1',
    fullName: 'Camilo',
    isOrganizer: true,
    lat: 4.6,
    lng: -74.1,
    recordedAt: DateTime.utc(2026, 9, 10, 12),
    updatedAt: DateTime.utc(2026, 9, 10, 12),
  );
}

void main() {
  late _MockWatchLiveRiders watchLiveRiders;
  late _MockWatchEventFinished watchEventFinished;
  late _MockGetPermissionState getPermissionState;
  late _MockStartSharing startSharing;
  late _MockStopSharing stopSharing;
  late _MockLocationService locationService;
  late _MockContactsCache contactsCache;
  late _MockBackgroundTrackingService backgroundTrackingService;
  late _MockGetEventDetail getEventDetail;

  setUp(() {
    watchLiveRiders = _MockWatchLiveRiders();
    watchEventFinished = _MockWatchEventFinished();
    getPermissionState = _MockGetPermissionState();
    startSharing = _MockStartSharing();
    stopSharing = _MockStopSharing();
    locationService = _MockLocationService();
    contactsCache = _MockContactsCache();
    backgroundTrackingService = _MockBackgroundTrackingService();
    getEventDetail = _MockGetEventDetail();

    when(() => watchLiveRiders(any())).thenAnswer((_) => const Stream.empty());
    when(
      () => watchEventFinished(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => getPermissionState(),
    ).thenAnswer((_) async => LocationPermissionState.whileInUse);
    when(() => contactsCache.read(any())).thenAnswer((_) async => null);
    when(
      () => backgroundTrackingService.isRunning(),
    ).thenAnswer((_) async => false);
    when(
      () => backgroundTrackingService.stoppedExternally,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => locationService.positionStream(
        distanceFilterMeters: any(named: 'distanceFilterMeters'),
      ),
    ).thenAnswer((_) => const Stream.empty());
  });

  LiveRideCubit buildCubit() => LiveRideCubit(
    watchLiveRiders,
    watchEventFinished,
    getPermissionState,
    startSharing,
    stopSharing,
    locationService,
    contactsCache,
    backgroundTrackingService,
    getEventDetail,
  );

  blocTest<LiveRideCubit, LiveRideState>(
    'load con riders emite ResultState.data',
    build: () {
      when(
        () => watchLiveRiders(any()),
      ).thenAnswer((_) => Stream.value(Right([_rider()])));
      return buildCubit();
    },
    act: (cubit) => cubit.load('event-1'),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.riders, isA<Data<List<LiveRider>>>());
    },
  );

  blocTest<LiveRideCubit, LiveRideState>(
    'load sin riders emite ResultState.empty',
    build: () {
      when(
        () => watchLiveRiders(any()),
      ).thenAnswer((_) => Stream.value(const Right([])));
      return buildCubit();
    },
    act: (cubit) => cubit.load('event-1'),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.riders, isA<Empty<List<LiveRider>>>());
    },
  );

  blocTest<LiveRideCubit, LiveRideState>(
    'un error del stream de riders emite ResultState.error',
    build: () {
      when(() => watchLiveRiders(any())).thenAnswer(
        (_) => Stream.value(
          const Left(DomainException(message: 'live_ride_offline')),
        ),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.load('event-1'),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) {
      expect(cubit.state.riders, isA<Error<List<LiveRider>>>());
    },
  );

  blocTest<LiveRideCubit, LiveRideState>(
    'startSharing exitoso pasa a sharing',
    build: () {
      when(
        () => startSharing(
          eventId: any(named: 'eventId'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
          stopButtonLabel: any(named: 'stopButtonLabel'),
        ),
      ).thenAnswer((_) async => const Right(unit));
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load('event-1');
      await cubit.startSharing(
        notificationTitle: 't',
        notificationBody: 'b',
        stopButtonLabel: 'Detener',
      );
    },
    verify: (cubit) {
      expect(cubit.state.sharing, SharingStatus.sharing);
    },
  );

  blocTest<LiveRideCubit, LiveRideState>(
    'startSharing fallido vuelve a notSharing',
    build: () {
      when(
        () => startSharing(
          eventId: any(named: 'eventId'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
          stopButtonLabel: any(named: 'stopButtonLabel'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          DomainException(message: 'live_ride_location_permission_denied'),
        ),
      );
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.load('event-1');
      await cubit.startSharing(
        notificationTitle: 't',
        notificationBody: 'b',
        stopButtonLabel: 'Detener',
      );
    },
    verify: (cubit) {
      expect(cubit.state.sharing, SharingStatus.notSharing);
    },
  );

  test('el fin del evento mientras se comparte llama a stopSharing', () async {
    final eventFinishedController = StreamController<bool>.broadcast();
    when(
      () => watchEventFinished(any()),
    ).thenAnswer((_) => eventFinishedController.stream);
    when(
      () => startSharing(
        eventId: any(named: 'eventId'),
        notificationTitle: any(named: 'notificationTitle'),
        notificationBody: any(named: 'notificationBody'),
        stopButtonLabel: any(named: 'stopButtonLabel'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(() => stopSharing(any())).thenAnswer((_) async => const Right(unit));

    final cubit = buildCubit();
    await cubit.load('event-1');
    await cubit.startSharing(
      notificationTitle: 't',
      notificationBody: 'b',
      stopButtonLabel: 'Detener',
    );
    expect(cubit.state.sharing, SharingStatus.sharing);

    eventFinishedController.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.isEventFinished, isTrue);
    verify(() => stopSharing('event-1')).called(1);

    await eventFinishedController.close();
    await cubit.close();
  });

  test('el botón "Detener" de la notificación pasa a notSharing sin llamar a '
      'StopSharingLocationUseCase de nuevo', () async {
    final stoppedExternallyController = StreamController<void>.broadcast();
    when(
      () => backgroundTrackingService.stoppedExternally,
    ).thenAnswer((_) => stoppedExternallyController.stream);
    when(
      () => backgroundTrackingService.isRunning(),
    ).thenAnswer((_) async => true);
    when(
      () => locationService.positionStream(
        distanceFilterMeters: any(named: 'distanceFilterMeters'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    final cubit = buildCubit();
    await cubit.load('event-1');
    expect(cubit.state.sharing, SharingStatus.sharing);

    stoppedExternallyController.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.sharing, SharingStatus.notSharing);
    expect(cubit.state.myPosition, isNull);
    verifyNever(() => stopSharing(any()));

    await stoppedExternallyController.close();
    await cubit.close();
  });

  blocTest<LiveRideCubit, LiveRideState>(
    'resolveArgs usa los args provistos sin llamar a GetEventDetailUseCase',
    build: buildCubit,
    act: (cubit) => cubit.resolveArgs(
      'event-1',
      const LiveRideRouteArgs(
        eventName: 'Rodada al Nevado del Ruiz',
        isOwner: true,
        ownerId: 'owner-1',
      ),
    ),
    expect: () => [
      isA<LiveRideState>().having(
        (state) => state.args,
        'args',
        const LiveRideRouteArgs(
          eventName: 'Rodada al Nevado del Ruiz',
          isOwner: true,
          ownerId: 'owner-1',
        ),
      ),
    ],
    verify: (_) => verifyNever(() => getEventDetail(any())),
  );

  blocTest<LiveRideCubit, LiveRideState>(
    'resolveArgs sin args (push de SOS) los resuelve con GetEventDetailUseCase',
    build: () {
      when(
        () => getEventDetail('event-1'),
      ).thenAnswer((_) async => Right(_event()));
      return buildCubit();
    },
    act: (cubit) => cubit.resolveArgs('event-1', null),
    expect: () => [
      isA<LiveRideState>().having(
        (state) => state.args,
        'args',
        const LiveRideRouteArgs(
          eventName: 'Rodada al Nevado del Ruiz',
          isOwner: false,
          ownerId: 'owner-1',
        ),
      ),
    ],
  );

  blocTest<LiveRideCubit, LiveRideState>(
    'resolveArgs con LiveRideRouteArgs.empty también dispara la resolución',
    build: () {
      when(
        () => getEventDetail('event-1'),
      ).thenAnswer((_) async => Right(_event()));
      return buildCubit();
    },
    act: (cubit) => cubit.resolveArgs('event-1', LiveRideRouteArgs.empty),
    expect: () => [
      isA<LiveRideState>().having(
        (state) => state.args.eventName,
        'eventName',
        'Rodada al Nevado del Ruiz',
      ),
    ],
  );
}
