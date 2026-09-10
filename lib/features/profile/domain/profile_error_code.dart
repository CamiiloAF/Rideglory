/// Códigos semánticos de error del feature de perfil/cuenta. Igual que en
/// auth: `data/` no puede traducir a español (no importa Flutter/l10n), así
/// que deja aquí el código y `presentation/` lo traduce con el `.arb`.
abstract final class ProfileErrorCode {
  static const String offline = 'profile_offline';
  static const String activeEventOrganizer = 'profile_active_event_organizer';
  static const String unknown = 'profile_unknown';
  static const String preferencesUnavailable =
      'profile_preferences_unavailable';
}
