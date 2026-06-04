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
  // Events — lectura (Fase 6)
  // ---------------------------------------------------------------------------

  /// Conteo de eventos próximos en home. Tipo: `int`. Max 40 chars: 22. ✓
  static const String upcomingEventsCount = 'upcoming_events_count';

  /// 1 si el rider tiene vehículo principal configurado, 0 si no.
  /// Tipo: `int` (0 ó 1). **Nunca** datos del vehículo (PII). Max 40 chars: 16. ✓
  static const String hasMainVehicle = 'has_main_vehicle';

  /// Conteo de resultados de la lista de eventos tras carga/filtro.
  /// Tipo: `int`. Max 40 chars: 12. ✓
  static const String resultCount = 'result_count';

  /// Alcance de la lista de eventos: `'all'` | `'mine'`.
  /// Tipo: `String`. Max 40 chars: 10. ✓
  static const String listScope = 'list_scope';

  /// Tipo de evento canónico (valor del enum, p.ej. `'tourism'`).
  /// **Nunca** el nombre libre del evento. Tipo: `String`. Max 40 chars: 10. ✓
  static const String eventType = 'event_type';

  /// Estado canónico del evento (p.ej. `'scheduled'`, `'draft'`).
  /// Tipo: `String`. Max 40 chars: 11. ✓
  static const String eventState = 'event_state';

  /// 1 si el rider autenticado es owner del evento, 0 si no. Nunca el uid/ownerId.
  /// Tipo: `int` (0 ó 1). Max 40 chars: 8. ✓
  static const String isOwner = 'is_owner';

  /// 1 si el evento se abrió en modo solo-lectura (borrador ajeno), 0 si no.
  /// Tipo: `int` (0 ó 1). Max 40 chars: 11. ✓
  static const String isReadOnly = 'is_read_only';

  /// Origen de la apertura del detalle: `'list'` | `'draft'` | `'deep_link'`.
  /// Tipo: `String`. Max 40 chars: 6. ✓
  static const String source = 'source';

  // Valores canónicos de list_scope
  /// Listado general (todos los eventos).
  static const String listScopeAll = 'all';

  /// Listado de mis eventos.
  static const String listScopeMine = 'mine';

  // Valores canónicos de source (detalle de evento)
  /// Apertura desde el listado general o "mis eventos".
  static const String sourceList = 'list';

  /// Apertura desde borradores.
  static const String sourceDraft = 'draft';

  /// Apertura directa por id (deep-link / push notification).
  static const String sourceDeepLink = 'deep_link';

  // ---------------------------------------------------------------------------
  // Events — escritura y registro (Fase 7)
  // ---------------------------------------------------------------------------

  /// Modo del formulario: `create` | `edit`.
  /// Tipo: `String`. Max key 40 chars: 9. ✓
  static const String formMode = 'form_mode';

  /// Categoría no-PII del fallo (escritura / submit): `network` | `validation`
  /// | `not_found` | `unknown`. **Nunca** el mensaje crudo.
  /// Tipo: `String`. Max key 40 chars: 16. ✓
  static const String failureCategory = 'failure_category';

  /// Índice del paso activo en el wizard (0-based).
  /// Tipo: `int`. Max key 40 chars: 10. ✓
  static const String stepIndex = 'step_index';

  /// Nombre canónico del paso activo (p.ej. `personal`, `medical`).
  /// **Nunca** datos del rider. Tipo: `String`. Max key 40 chars: 9. ✓
  static const String stepName = 'step_name';

  /// Acción de aprobación: `approve` | `reject` | `ready_for_edit`.
  /// Tipo: `String`. Max key 40 chars: 15. ✓
  static const String approvalAction = 'approval_action';

  // ---------------------------------------------------------------------------
  // Live tracking / SOS — params no-PII (Fase 8)
  //
  // PROHIBIDO como valor: coordenadas lat/lng, uid de usuario, nombre, teléfono,
  // id de evento. Solo enums cerrados y agregados de baja cardinalidad.
  // ---------------------------------------------------------------------------

  /// Rol del rider en la rodada: `lead` | `rider`.
  /// Tipo: `String`. Max key 40 chars: 16. ✓
  static const String trackingRole = 'tracking_role';

  /// Razón de fin de sesión de tracking: `user_left` | `event_ended` |
  /// `signed_out`.
  /// Tipo: `String`. Max key 40 chars: 18. ✓
  static const String trackingEndReason = 'tracking_end_reason';

  /// Número de riders en el primer snapshot de la sesión (agregado de baja
  /// cardinalidad). Tipo: `int`. Max key 40 chars: 12. ✓
  static const String riderCount = 'rider_count';

  /// Razón de limpieza del SOS: `user_cancel` | `remote_clear`.
  /// Tipo: `String`. Max key 40 chars: 16. ✓
  static const String sosClearReason = 'sos_clear_reason';

  // Valores canónicos de form_mode
  /// Formulario en modo creación.
  static const String formModeCreate = 'create';

  /// Formulario en modo edición.
  static const String formModeEdit = 'edit';

  // Valores canónicos de failure_category
  /// Fallo por error de red / timeout.
  static const String failureCategoryNetwork = 'network';

  /// Fallo por validación local del formulario.
  static const String failureCategoryValidation = 'validation';

  /// Fallo porque el recurso no existe (404).
  static const String failureCategoryNotFound = 'not_found';

  /// Fallo no clasificado.
  static const String failureCategoryUnknown = 'unknown';

  // Valores canónicos de approval_action
  /// Acción de aprobar inscripción.
  static const String approvalActionApprove = 'approve';

  /// Acción de rechazar inscripción.
  static const String approvalActionReject = 'reject';

  /// Acción de marcar "listo para editar".
  static const String approvalActionReadyForEdit = 'ready_for_edit';

  // Valores canónicos de step_name (wizard de registro)
  /// Paso de datos personales.
  static const String stepNamePersonal = 'personal';

  /// Paso de datos médicos.
  static const String stepNameMedical = 'medical';

  /// Paso de contacto de emergencia.
  static const String stepNameEmergency = 'emergency';

  /// Paso de selección de vehículo.
  static const String stepNameVehicle = 'vehicle';

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

  // Valores canónicos de tracking_role (Fase 8)
  /// El rider es el organizador/líder de la rodada.
  static const String trackingRoleLead = 'lead';

  /// El rider es participante de la rodada.
  static const String trackingRoleRider = 'rider';

  // Valores canónicos de tracking_end_reason (Fase 8)
  /// El rider salió voluntariamente de la pantalla de tracking.
  static const String trackingEndReasonUserLeft = 'user_left';

  /// El organizador terminó la rodada (eventEnded).
  static const String trackingEndReasonEventEnded = 'event_ended';

  /// El rider cerró sesión mientras el tracking estaba activo.
  static const String trackingEndReasonSignedOut = 'signed_out';

  // Valores canónicos de sos_clear_reason (Fase 8)
  /// El propio rider canceló su SOS.
  static const String sosClearReasonUserCancel = 'user_cancel';

  /// El SOS fue cerrado por evento remoto del gateway.
  static const String sosClearReasonRemoteClear = 'remote_clear';

  // ---------------------------------------------------------------------------
  // Vehículos (Fase 9)
  // ---------------------------------------------------------------------------

  /// 1 si el vehículo tenía foto al guardar, 0 si no.
  /// Tipo: `int` (0 ó 1). **Nunca** la URL ni el path. Max 40 chars: 9. ✓
  static const String hadPhoto = 'had_photo';

  // ---------------------------------------------------------------------------
  // Mantenimiento (Fase 9)
  // ---------------------------------------------------------------------------

  /// Tipo de mantenimiento canónico (enum name, p.ej. `oilChange`).
  /// **Nunca** notas libres ni IDs. Tipo: `String`. Max key 40 chars: 16. ✓
  static const String maintenanceType = 'maintenance_type';

  /// Modo del mantenimiento: `completed` | `scheduled`.
  /// Tipo: `String`. Max key 40 chars: 16. ✓
  static const String maintenanceMode = 'maintenance_mode';

  // Valores canónicos de maintenance_mode
  /// Mantenimiento completado.
  static const String maintenanceModeCompleted = 'completed';

  /// Mantenimiento programado.
  static const String maintenanceModeScheduled = 'scheduled';

  // ---------------------------------------------------------------------------
  // SOAT (Fase 9)
  // ---------------------------------------------------------------------------

  /// Estado canónico del SOAT: `valid` | `expiringSoon` | `expired` | `noSoat`.
  /// Tipo: `String`. Max key 40 chars: 11. ✓
  static const String soatStatus = 'soat_status';

  // ---------------------------------------------------------------------------
  // Tecnomecánica (RTM)
  // ---------------------------------------------------------------------------

  /// Estado canónico de la RTM: `valid` | `expiringSoon` | `expired` | `none`.
  /// Tipo: `String`. Max key 40 chars: 10. ✓
  static const String rtmStatus = 'rtm_status';

  // ---------------------------------------------------------------------------
  // Notificaciones (Fase 9)
  // ---------------------------------------------------------------------------

  /// Tipo canónico de notificación (enum name, p.ej. `general`).
  /// **Nunca** el id ni el texto de la notificación. Tipo: `String`. Max key 40 chars: 17. ✓
  static const String notificationType = 'notification_type';
}
