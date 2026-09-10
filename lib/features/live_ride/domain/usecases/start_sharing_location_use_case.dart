import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../active_live_ride_tracker.dart';
import '../background_tracking_service.dart';
import '../live_ride_contacts_cache.dart';
import '../live_ride_error_code.dart';
import '../live_ride_repository.dart';
import '../location_permission_state.dart';
import '../location_service.dart';

/// Orquesta D17 + D21 al pulsar "Compartir mi ubicación": el permiso ya se
/// pide en la hoja de consentimiento propia (LV2, `presentation/`) antes de
/// llegar aquí — este caso de uso asume que ese diálogo del sistema ya
/// corrió y solo verifica el resultado, cachea el contacto de emergencia y
/// el teléfono del organizador, y arranca el servicio nativo.
@injectable
class StartSharingLocationUseCase {
  const StartSharingLocationUseCase(
    this._locationService,
    this._repository,
    this._contactsCache,
    this._backgroundTrackingService,
    this._activeLiveRideTracker,
  );

  final LocationService _locationService;
  final LiveRideRepository _repository;
  final LiveRideContactsCache _contactsCache;
  final BackgroundTrackingService _backgroundTrackingService;
  final ActiveLiveRideTracker _activeLiveRideTracker;

  Future<Either<DomainException, Unit>> call({
    required String eventId,
    required String notificationTitle,
    required String notificationBody,
    required String stopButtonLabel,
  }) async {
    final permission = await _locationService.permissionState();
    final permissionError = _permissionErrorFor(permission);
    if (permissionError != null) return Left(permissionError);

    final contactsResult = await _repository.getContacts(eventId);
    return contactsResult.fold((error) async => Left(error), (contacts) async {
      await _contactsCache.save(eventId, contacts);
      await _backgroundTrackingService.start(
        eventId: eventId,
        notificationTitle: notificationTitle,
        notificationBody: notificationBody,
        stopButtonLabel: stopButtonLabel,
      );
      // Logout (D22 extra): `SignOutUseCase` necesita saber qué rodada
      // parar sin depender de que `LiveRideCubit` siga vivo.
      await _activeLiveRideTracker.save(eventId);
      return const Right(unit);
    });
  }

  DomainException? _permissionErrorFor(LocationPermissionState permission) {
    return switch (permission) {
      LocationPermissionState.whileInUse ||
      LocationPermissionState.always => null,
      LocationPermissionState.serviceDisabled => const DomainException(
        message: LiveRideErrorCode.locationServiceDisabled,
      ),
      LocationPermissionState.denied ||
      LocationPermissionState.deniedForever => const DomainException(
        message: LiveRideErrorCode.locationPermissionDenied,
      ),
    };
  }
}
