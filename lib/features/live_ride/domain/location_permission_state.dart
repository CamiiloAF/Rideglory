/// Estado de permiso de ubicación del dispositivo, incluyendo el estado del
/// servicio del sistema (GPS). D21: se pide "mientras usa la app"
/// (`whileInUse`) primero; "todo el tiempo" (`always`) es un segundo paso
/// explícito para la notificación persistente del tracking en segundo
/// plano.
enum LocationPermissionState {
  denied,
  deniedForever,
  whileInUse,
  always,
  serviceDisabled,
}
