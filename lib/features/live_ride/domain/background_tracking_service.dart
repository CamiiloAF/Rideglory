/// Servicio nativo (foreground service en Android, `location` en
/// `UIBackgroundModes` en iOS) que sigue publicando posiciones aunque la
/// app esté en segundo plano. D14. La notificación persistente incluye un
/// botón **Detener** que el rider puede pulsar aunque la app esté cerrada.
abstract class BackgroundTrackingService {
  Future<void> start({
    required String eventId,
    required String notificationTitle,
    required String notificationBody,
    required String stopButtonLabel,
  });

  /// D22: para el servicio nativo. Idempotente: llamarlo sin que esté
  /// corriendo no falla.
  Future<void> stop();

  Future<bool> isRunning();
}
