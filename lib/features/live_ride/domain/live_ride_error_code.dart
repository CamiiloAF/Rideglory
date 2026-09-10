/// Códigos semánticos para los errores de negocio de `live_ride`, resueltos
/// a texto en la capa de presentación vía el `.arb` — nunca el mensaje
/// crudo del SDK o de Postgres. Los primeros cuatro llegan tal cual del
/// servidor (RPCs de `supabase-backend-dev`); los siguientes son del
/// cliente (permiso y disponibilidad de ubicación).
abstract final class LiveRideErrorCode {
  static const String notAParticipant = 'live_ride_not_a_participant';
  static const String eventNotStarted = 'live_ride_event_not_started';
  static const String sosNotFound = 'live_ride_sos_not_found';
  static const String notAllowedToClose = 'live_ride_not_allowed_to_close';

  static const String locationPermissionDenied =
      'live_ride_location_permission_denied';
  static const String locationServiceDisabled =
      'live_ride_location_service_disabled';
  static const String locationUnavailable = 'live_ride_location_unavailable';

  static const String offline = 'live_ride_offline';
  static const String unknown = 'live_ride_unknown';
}
