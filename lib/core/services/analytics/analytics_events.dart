/// Catálogo centralizado de nombres de evento para Firebase Analytics.
///
/// Convenciones de naming:
/// - snake_case, prefijo por feature (p.ej. `soat_`, `auth_`, `event_`).
/// - Máximo 40 caracteres por nombre (límite GA4 — verificar con `.length`
///   si se añaden nombres largos).
/// - No usar palabras reservadas de GA4 (e.g. `login` sin prefijo está
///   reservado; usar `auth_login` si se instrumenta en fases siguientes).
///
/// Política no-PII (GA4 / Crashlytics):
/// Ningún nombre de evento puede incluir ids dinámicos, emails, nombres,
/// placas, VIN, coordenadas ni nombres de aseguradoras. Solo categorías
/// y acciones estables.
abstract final class AnalyticsEvents {
  // ---------------------------------------------------------------------------
  // Auth / Acquisition funnel (Fase 5)
  // ---------------------------------------------------------------------------

  /// El rider entra a una vista de autenticación (login, signup, forgot_password).
  /// Param: [AnalyticsParams.authMethod].
  /// Max 40 chars: 'auth_flow_started'.length == 17. ✓
  static const String authFlowStarted = 'auth_flow_started';

  /// El rider elige un método concreto (email, google, apple) al pulsar el
  /// botón de submit / social. Param: [AnalyticsParams.authMethod].
  /// Max 40 chars: 'auth_method_selected'.length == 20. ✓
  static const String authMethodSelected = 'auth_method_selected';

  /// El cubit confirma sesión exitosa. Param: [AnalyticsParams.authMethod].
  /// Max 40 chars: 'auth_succeeded'.length == 14. ✓
  static const String authSucceeded = 'auth_succeeded';

  /// El cubit recibe un error de auth. Params: [AnalyticsParams.authMethod],
  /// [AnalyticsParams.authErrorCategory]. **Sin PII.**
  /// Max 40 chars: 'auth_failed'.length == 11. ✓
  static const String authFailed = 'auth_failed';

  /// El rider sale de una vista de auth sin completar el flujo (dispose/back
  /// sin [AuthState.authenticated]). Param: [AnalyticsParams.authMethod].
  /// Max 40 chars: 'auth_abandoned'.length == 14. ✓
  static const String authAbandoned = 'auth_abandoned';

  /// Primera entrada a home tras autenticarse — cierre del embudo de
  /// adquisición. Sin params PII. Una vez por sesión de adquisición.
  /// Max 40 chars: 'auth_first_home_entry'.length == 21. ✓
  static const String authFirstHomeEntry = 'auth_first_home_entry';

  // ---------------------------------------------------------------------------
  // SOAT
  // ---------------------------------------------------------------------------

  /// El usuario inicia un escaneo de SOAT (primera acción del flujo).
  /// Max 40 chars: 'soat_scan_attempted'.length == 19. ✓
  static const String soatScanAttempted = 'soat_scan_attempted';

  /// El escaneo terminó con éxito y se prefillaron los campos del SOAT.
  /// Max 40 chars: 'soat_scan_success'.length == 17. ✓
  static const String soatScanSuccess = 'soat_scan_success';

  /// El escaneo falló (baja confianza, sin texto, validación, etc.).
  /// Max 40 chars: 'soat_scan_failed'.length == 16. ✓
  static const String soatScanFailed = 'soat_scan_failed';

  // ---------------------------------------------------------------------------
  // Events — lectura (Fase 6)
  // ---------------------------------------------------------------------------

  /// El rider aterrizó en home con datos cargados exitosamente.
  /// Params: [AnalyticsParams.upcomingEventsCount], [AnalyticsParams.hasMainVehicle].
  /// Max 40 chars: 'home_viewed'.length == 11. ✓
  static const String homeViewed = 'home_viewed';

  /// El rider vio una lista de eventos tras una carga real contra el backend
  /// (carga inicial o recarga por cambio de filtros). NO se emite por keystroke
  /// de búsqueda ni por mutaciones locales (addEvent/updateEvent/removeEvent).
  /// Params: [AnalyticsParams.resultCount], [AnalyticsParams.listScope].
  /// Max 40 chars: 'events_list_viewed'.length == 18. ✓
  static const String eventsListViewed = 'events_list_viewed';

  /// El rider abrió el detalle de un evento (una sola vez por apertura).
  /// Params: [AnalyticsParams.eventType], [AnalyticsParams.eventState],
  /// [AnalyticsParams.isOwner], [AnalyticsParams.isReadOnly],
  /// [AnalyticsParams.source]. Sin PII: nunca event_id, nombre ni city.
  /// Max 40 chars: 'event_detail_viewed'.length == 19. ✓
  static const String eventDetailViewed = 'event_detail_viewed';
}
