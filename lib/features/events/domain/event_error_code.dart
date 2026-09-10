/// Códigos semánticos para los errores de negocio de `events`, resueltos a
/// texto en la capa de presentación vía el `.arb` — nunca el mensaje crudo
/// del SDK o de Postgres.
abstract final class EventErrorCode {
  static const String underage = 'event_underage';
  static const String birthDateRequired = 'event_birth_date_required';
  static const String alreadyRegistered = 'event_already_registered';
  static const String offline = 'event_offline';
  static const String unknown = 'event_unknown';
}
