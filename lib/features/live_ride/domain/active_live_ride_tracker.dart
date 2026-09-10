/// D22/logout: recuerda qué rodada tiene el tracking nativo activo, fuera
/// del ciclo de vida de `LiveRideCubit` (que se destruye al salir de la
/// pantalla, pero el foreground service sigue corriendo). Hoy lo usa
/// `SignOutUseCase` para parar el tracking **antes** de cerrar sesión —
/// sin esto, cerrar sesión desde otra pantalla deja el servicio nativo
/// publicando posiciones con una sesión que la app ya olvidó.
///
/// Implementado en `data/` sobre el mismo storage que usa
/// `FlutterForegroundTask` (`saveData`/`getData`/`removeData`), que a
/// diferencia de `shared_preferences` "a pelo" es accesible tanto desde
/// el isolate principal como desde el del foreground service — el botón
/// "Detener" de la notificación también lo limpia.
abstract class ActiveLiveRideTracker {
  Future<void> save(String eventId);

  Future<String?> read();

  Future<void> clear();
}
