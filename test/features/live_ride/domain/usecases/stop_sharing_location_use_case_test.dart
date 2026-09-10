import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/live_ride/domain/active_live_ride_tracker.dart';
import 'package:rideglory/features/live_ride/domain/background_tracking_service.dart';
import 'package:rideglory/features/live_ride/domain/live_ride_contacts_cache.dart';
import 'package:rideglory/features/live_ride/domain/live_ride_repository.dart';
import 'package:rideglory/features/live_ride/domain/usecases/stop_sharing_location_use_case.dart';

class _MockBackgroundTrackingService extends Mock
    implements BackgroundTrackingService {}

class _MockLiveRideRepository extends Mock implements LiveRideRepository {}

class _MockLiveRideContactsCache extends Mock
    implements LiveRideContactsCache {}

class _MockActiveLiveRideTracker extends Mock
    implements ActiveLiveRideTracker {}

void main() {
  late _MockBackgroundTrackingService backgroundTrackingService;
  late _MockLiveRideRepository repository;
  late _MockLiveRideContactsCache contactsCache;
  late _MockActiveLiveRideTracker activeLiveRideTracker;
  late StopSharingLocationUseCase useCase;

  setUp(() {
    backgroundTrackingService = _MockBackgroundTrackingService();
    repository = _MockLiveRideRepository();
    contactsCache = _MockLiveRideContactsCache();
    activeLiveRideTracker = _MockActiveLiveRideTracker();
    useCase = StopSharingLocationUseCase(
      backgroundTrackingService,
      repository,
      contactsCache,
      activeLiveRideTracker,
    );

    when(() => backgroundTrackingService.stop()).thenAnswer((_) async {});
    when(
      () => repository.endRide(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(() => contactsCache.clear(any())).thenAnswer((_) async {});
    when(() => activeLiveRideTracker.clear()).thenAnswer((_) async {});
  });

  test('para el servicio nativo, termina la rodada en el servidor, borra la '
      'caché de contactos y la rodada activa', () async {
    await useCase.call('event-1');

    verify(() => backgroundTrackingService.stop()).called(1);
    verify(() => repository.endRide('event-1')).called(1);
    verify(() => contactsCache.clear('event-1')).called(1);
    verify(() => activeLiveRideTracker.clear()).called(1);
  });

  test(
    'nunca toca un SOS: no interactúa con ningún repositorio de SOS',
    () async {
      // No hay dependencia de SosRepository/SosOutbox en el constructor:
      // este test documenta esa garantía estructural. Si alguien la agrega
      // sin querer, este test deja de compilar.
      await useCase.call('event-1');
      verify(() => backgroundTrackingService.stop()).called(1);
      verifyNoMoreInteractions(backgroundTrackingService);
    },
  );
}
