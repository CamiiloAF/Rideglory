/// Nivel de batería del dispositivo (`battery_plus`), para completar el
/// `batteryPct` de un [RiderPosition] antes de publicarlo. Separado de
/// [LocationService] porque el GPS no conoce la batería.
abstract class BatteryService {
  Future<int?> currentLevel();
}
