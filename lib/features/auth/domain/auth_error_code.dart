/// Códigos semánticos de error de autenticación.
///
/// `DomainException.message` para este feature nunca es texto para mostrar
/// al usuario: es uno de estos códigos, y la capa de presentación lo traduce
/// con `AuthErrorTranslator` a una cadena del `.arb`. `data/` no puede
/// importar Flutter/l10n, así que el mapeo a español vive del otro lado.
abstract final class AuthErrorCode {
  static const String invalidCredentials = 'auth_invalid_credentials';
  static const String emailAlreadyRegistered = 'auth_email_already_registered';
  static const String weakPassword = 'auth_weak_password';
  static const String userNotFound = 'auth_user_not_found';
  static const String providerCancelled = 'auth_provider_cancelled';
  static const String offline = 'auth_offline';
  static const String unknown = 'auth_unknown';
}
