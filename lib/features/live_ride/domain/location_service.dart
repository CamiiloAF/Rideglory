import 'location_permission_state.dart';
import 'rider_position.dart';

/// Acceso a la ubicación del dispositivo. `batteryPct` de las posiciones
/// que devuelve siempre viene `null`: la batería la resuelve por separado
/// quien construya el [RiderPosition] final (no es responsabilidad del
/// GPS).
abstract class LocationService {
  Future<LocationPermissionState> permissionState();

  /// D21: primer paso, "mientras usa la app".
  Future<LocationPermissionState> requestWhileInUse();

  /// D21: segundo paso explícito, para el tracking en segundo plano.
  Future<LocationPermissionState> requestAlways();

  Future<bool> isServiceEnabled();

  /// Intenta una lectura fresca con [timeout] (5 s en `RaiseSosUseCase`);
  /// si no llega a tiempo, cae a la última posición conocida del sistema.
  /// `null` solo si el dispositivo nunca tuvo una posición.
  Future<RiderPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 5),
  });

  Stream<RiderPosition> positionStream({double distanceFilterMeters = 25});
}
