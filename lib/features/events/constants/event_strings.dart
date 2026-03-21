abstract class EventStrings {
  static const String trackingEventMissing =
      'No se pudo abrir el mapa: evento sin identificador.';
  static const String trackingLoadRidersFailed =
      'No pudimos cargar la ubicación de los riders. Intenta de nuevo.';
  static const String trackingStartFailed =
      'No pudimos iniciar el seguimiento de tu ubicación.';
  static const String trackingDefaultDeviceLabel = 'Dispositivo móvil';
  static const String trackingBatteryUnknown = 'N/D';
  static const String trackingDistanceUnavailable = 'N/D';
  static const String trackingLiveMapOnlyWhenInProgress =
      'El mapa en vivo solo está disponible mientras el evento está en curso.';
  static const String trackingNoActiveRiders =
      'Aún no hay riders compartiendo ubicación.';
  static const String trackingForegroundServiceTitle =
      'Seguimiento de rodada activo';
  static const String trackingForegroundServiceBody =
      'Rideglory sigue compartiendo tu ubicación con el evento.';
  static const String trackingForegroundServiceChannelName =
      'Seguimiento en vivo';
}
