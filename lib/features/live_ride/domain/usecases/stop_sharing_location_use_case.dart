import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../background_tracking_service.dart';
import '../live_ride_contacts_cache.dart';
import '../live_ride_repository.dart';

/// D22: termina el tracking del rider actual. Para el servicio nativo
/// primero (aunque `end_live_ride` falle, el foreground service no debe
/// seguir corriendo), llama a `end_live_ride` y borra la caché de
/// contactos. **Nunca toca un SOS activo** — un SOS solo lo cierra una
/// persona (D19).
@injectable
class StopSharingLocationUseCase {
  const StopSharingLocationUseCase(
    this._backgroundTrackingService,
    this._repository,
    this._contactsCache,
  );

  final BackgroundTrackingService _backgroundTrackingService;
  final LiveRideRepository _repository;
  final LiveRideContactsCache _contactsCache;

  Future<Either<DomainException, Unit>> call(String eventId) async {
    await _backgroundTrackingService.stop();
    final result = await _repository.endRide(eventId);
    await _contactsCache.clear(eventId);
    return result;
  }
}
