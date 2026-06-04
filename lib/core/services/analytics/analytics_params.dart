/// Catálogo centralizado de claves de parámetros para Firebase Analytics.
///
/// Límites GA4:
/// - Clave de parámetro: máximo **40 caracteres**.
/// - Valor string: máximo **100 caracteres**.
/// - Tipo de `parameters`: siempre `Map<String, Object>`.
/// - **Prohibido `bool`** — usar `int` 0/1 (GA4 descarta booleanos silenciosamente).
///
/// Política no-PII:
/// Las *claves* son constantes estables. Los *valores* que se envíen deben ser
/// agregados o enumerados (p.ej. `insurer_detected: 0/1`, no el nombre).
/// Campos prohibidos como valores: email, nombre, placa, VIN, nombre de
/// aseguradora, coordenadas lat/lng, ids dinámicos de evento/registro/rider.
abstract final class AnalyticsParams {
  // ---------------------------------------------------------------------------
  // Auth / Acquisition funnel (Fase 5)
  // ---------------------------------------------------------------------------

  /// Método de autenticación: `email` | `google` | `apple` | `login` |
  /// `signup` | `forgot_password` (contexto del flujo o acción concreta).
  /// Tipo: `String`. Max key 40 chars: 11. ✓
  static const String authMethod = 'auth_method';

  /// Categoría no-PII del error de auth: `invalid_credentials` | `network` |
  /// `cancelled` | `unknown`. **Nunca** el mensaje crudo.
  /// Tipo: `String`. Max key 40 chars: 19. ✓
  static const String authErrorCategory = 'auth_error_category';

  // Valores canónicos de auth_method (flujo de inicio)
  /// Flujo de login por email.
  static const String authMethodLogin = 'login';

  /// Flujo de registro por email.
  static const String authMethodSignup = 'signup';

  /// Flujo de recuperación de contraseña.
  static const String authMethodForgotPassword = 'forgot_password';

  /// Método concreto: correo + contraseña.
  static const String authMethodEmail = 'email';

  /// Método concreto: Google OAuth.
  static const String authMethodGoogle = 'google';

  /// Método concreto: Apple OAuth.
  static const String authMethodApple = 'apple';

  // Valores canónicos de auth_error_category (sin PII)
  /// Credenciales inválidas (user-not-found, wrong-password, invalid-credential).
  static const String authErrorInvalidCredentials = 'invalid_credentials';

  /// Error de red (network-request-failed, timeouts).
  static const String authErrorNetwork = 'network';

  /// Flujo cancelado por el usuario (sign_in_cancelled, etc.).
  static const String authErrorCancelled = 'cancelled';

  /// Error no clasificado.
  static const String authErrorUnknown = 'unknown';

  // ---------------------------------------------------------------------------
  // User properties (Fase 5)
  // ---------------------------------------------------------------------------

  /// Nombre de la user property que almacena el método de login más reciente.
  /// Valor: constante de [authMethod*] (email | google | apple). Sin PII.
  static const String userPropertyLoginMethod = 'login_method';

  /// Nombre de la user property que indica si el rider tiene al menos un
  /// vehículo registrado (0 = no, 1 = sí). Se asigna en VehicleCubit tras
  /// fetchMyVehicles — no requiere llamada extra al backend.
  static const String userPropertyHasVehicle = 'has_vehicle';

  // ---------------------------------------------------------------------------
  // SOAT
  // ---------------------------------------------------------------------------

  /// Número de campos extraídos del documento SOAT.
  /// Tipo: `int`. No incluye texto del documento. Max 40 chars: 22. ✓
  static const String fieldsExtractedCount = 'fields_extracted_count';

  /// 1 si se detectó aseguradora conocida, 0 si no.
  /// Tipo: `int` (0 ó 1). **Nunca** el nombre de la aseguradora (PII / alta
  /// cardinalidad). Max 40 chars: 17. ✓
  static const String insurerDetected = 'insurer_detected';

  /// 1 si el documento era un PDF, 0 si era imagen.
  /// Tipo: `int` (0 ó 1). Max 40 chars: 7. ✓
  static const String hadPdf = 'had_pdf';

  /// Razón del fallo del escaneo (valor enumerado, p.ej. `no_text_detected`).
  /// Tipo: `String` (≤100 chars). Max key 40 chars: 14. ✓
  static const String failureReason = 'failure_reason';

  // ---------------------------------------------------------------------------
  // Red / errores (Fase 4 — no-fatales de Crashlytics)
  // ---------------------------------------------------------------------------

  /// Categoría del error: `network`, `platform_unexpected`, `unexpected`.
  /// Tipo: `String`. Max 40 chars: 14. ✓
  static const String errorCategory = 'error_category';

  /// Código HTTP de estado (p.ej. `500`). Ausente si no aplica.
  /// Tipo: `int`. Max 40 chars: 11. ✓
  static const String httpStatus = 'http_status';

  /// Nombre del tipo de `DioExceptionType` (p.ej. `connectionTimeout`).
  /// Tipo: `String`. Max 40 chars: 8. ✓
  static const String dioType = 'dio_type';

  /// Host + path del endpoint con segmentos dinámicos enmascarados.
  /// **Sin** query string, body, tokens, ni ids. Max 40 chars: 8. ✓
  static const String endpoint = 'endpoint';

  // ---------------------------------------------------------------------------
  // Valores de categoría (error_category) — constantes para evitar strings
  // mágicos en handlerExceptionHttp.
  // ---------------------------------------------------------------------------

  /// Errores de red (Dio timeouts, 5xx, connectionError, badCertificate, etc.).
  static const String categoryNetwork = 'network';

  /// PlatformException con código no esperado.
  static const String categoryPlatformUnexpected = 'platform_unexpected';

  /// Error genérico no anticipado (catch genérico).
  static const String categoryUnexpected = 'unexpected';

  // ---------------------------------------------------------------------------
  // Valores de reason (cadenas cortas para el campo `reason` de CrashReporter)
  // ---------------------------------------------------------------------------

  /// Timeout de conexión / envío / recepción.
  static const String reasonNetworkTimeout = 'network_timeout';

  /// Error de conexión / bad certificate.
  static const String reasonNetworkConnection = 'network_connection';

  /// Respuesta HTTP 5xx.
  static const String reasonNetwork5xx = 'network_5xx';

  /// FirebaseAuthException de tipo `network-request-failed`.
  static const String reasonFirebaseNetwork = 'firebase_network';

  /// PlatformException con código inesperado.
  static const String reasonPlatformUnexpected = 'platform_unexpected';
}
