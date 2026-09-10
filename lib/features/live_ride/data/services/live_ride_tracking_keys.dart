/// Claves compartidas entre el isolate principal
/// (`ForegroundTaskBackgroundTrackingService`) y el del foreground service
/// (`LiveRideTrackingTaskHandler`), todas respaldadas por
/// `FlutterForegroundTask.saveData`/`getData`/`removeData` — el único
/// storage confiable entre ambos isolates (ver comentario del handler).
/// Vivir en un solo archivo evita que un typo en una punta rompa la otra
/// en silencio.
abstract final class LiveRideTrackingKeys {
  static const String eventId = 'live_ride_event_id';
  static const String accessToken = 'live_ride_access_token';
  static const String refreshToken = 'live_ride_refresh_token';
  static const String stopButtonId = 'live_ride_stop';

  /// D22/logout: qué rodada tiene el tracking activo (ver
  /// `ActiveLiveRideTracker`). El handler la borra al terminar por
  /// cualquier vía (botón de la notificación, `onDestroy`).
  static const String activeEventId = 'live_ride.active_event_id';

  /// Mensaje que el handler manda por `sendDataToMain` cuando el
  /// tracking terminó por fuera de `StopSharingLocationUseCase` (botón
  /// "Detener" de la notificación, o el sistema matando el servicio) —
  /// `LiveRideCubit` lo escucha para pasar a `notSharing` sin que el
  /// rider tenga que reabrir la app.
  static const String stoppedExternallyMessage = 'live_ride_stopped';
}
