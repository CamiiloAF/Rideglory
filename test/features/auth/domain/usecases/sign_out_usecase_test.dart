import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/auth/domain/auth_repository.dart';
import 'package:rideglory/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:rideglory/features/live_ride/domain/active_live_ride_tracker.dart';
import 'package:rideglory/features/live_ride/domain/usecases/stop_sharing_location_use_case.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockStopSharingLocationUseCase extends Mock
    implements StopSharingLocationUseCase {}

class _MockActiveLiveRideTracker extends Mock
    implements ActiveLiveRideTracker {}

/// Gate de seguridad: cerrar sesión con una rodada en curso no puede dejar
/// el foreground service publicando posiciones con una sesión que la app
/// ya olvidó.
void main() {
  late _MockAuthRepository repository;
  late _MockStopSharingLocationUseCase stopSharingLocation;
  late _MockActiveLiveRideTracker activeLiveRideTracker;
  late SignOutUseCase useCase;

  setUp(() {
    repository = _MockAuthRepository();
    stopSharingLocation = _MockStopSharingLocationUseCase();
    activeLiveRideTracker = _MockActiveLiveRideTracker();
    useCase = SignOutUseCase(
      repository,
      stopSharingLocation,
      activeLiveRideTracker,
    );

    when(() => repository.signOut()).thenAnswer((_) async {});
  });

  test(
    'con una rodada activa, detiene el tracking antes de cerrar sesión',
    () async {
      when(
        () => activeLiveRideTracker.read(),
      ).thenAnswer((_) async => 'event-1');
      when(
        () => stopSharingLocation('event-1'),
      ).thenAnswer((_) async => const Right(unit));

      await useCase.call();

      verifyInOrder([
        () => activeLiveRideTracker.read(),
        () => stopSharingLocation('event-1'),
        () => repository.signOut(),
      ]);
    },
  );

  test('sin rodada activa, no detiene ningún tracking', () async {
    when(() => activeLiveRideTracker.read()).thenAnswer((_) async => null);

    await useCase.call();

    verifyNever(() => stopSharingLocation(any()));
    verify(() => repository.signOut()).called(1);
  });

  test('un fallo al detener el tracking no bloquea el logout', () async {
    when(() => activeLiveRideTracker.read()).thenAnswer((_) async => 'event-1');
    when(() => stopSharingLocation('event-1')).thenThrow(Exception('sin red'));

    await useCase.call();

    verify(() => repository.signOut()).called(1);
  });

  test('nunca interactúa con un repositorio de SOS', () async {
    // No hay dependencia de SosRepository/SosOutbox en el constructor:
    // este test documenta esa garantía estructural, igual que
    // `StopSharingLocationUseCase`. Si alguien la agrega sin querer, este
    // test deja de compilar.
    when(() => activeLiveRideTracker.read()).thenAnswer((_) async => null);

    await useCase.call();

    verify(() => repository.signOut()).called(1);
  });
}
