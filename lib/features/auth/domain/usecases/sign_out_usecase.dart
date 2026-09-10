import 'package:injectable/injectable.dart';

import '../../../live_ride/domain/active_live_ride_tracker.dart';
import '../../../live_ride/domain/usecases/stop_sharing_location_use_case.dart';
import '../auth_repository.dart';

/// Cierra la sesión de Supabase. Gate de seguridad del rider: si hay una
/// rodada con el tracking nativo activo (`ActiveLiveRideTracker`, escrito
/// por `StartSharingLocationUseCase` al empezar a compartir), se detiene
/// **antes** de `signOut` — para el servicio nativo, llama a
/// `end_live_ride` y borra la caché de contactos. Sin esto, cerrar sesión
/// desde otra pantalla deja el foreground service publicando posiciones
/// con una sesión que la app ya olvidó. Nunca toca un SOS activo
/// (`StopSharingLocationUseCase` no conoce `SosRepository`).
@injectable
class SignOutUseCase {
  SignOutUseCase(
    this._repository,
    this._stopSharingLocation,
    this._activeLiveRideTracker,
  );

  final AuthRepository _repository;
  final StopSharingLocationUseCase _stopSharingLocation;
  final ActiveLiveRideTracker _activeLiveRideTracker;

  Future<void> call() async {
    final activeEventId = await _activeLiveRideTracker.read();
    if (activeEventId != null) {
      try {
        await _stopSharingLocation(activeEventId);
      } catch (_) {
        // El logout nunca debe quedar bloqueado por el tracking: mejor
        // esfuerzo, igual que el resto de `StopSharingLocationUseCase`.
      }
    }
    await _repository.signOut();
  }
}
