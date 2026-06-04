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

  // ---------------------------------------------------------------------------
  // Events — escritura (Fase 7)
  // ---------------------------------------------------------------------------

  /// El rider inicia el formulario de creación o edición de evento.
  /// Param: [AnalyticsParams.formMode] (`create` | `edit`).
  /// Max 40 chars: 'events_create_started'.length == 21. ✓
  static const String eventsCreateStarted = 'events_create_started';

  /// El rider guardó el evento como borrador exitosamente.
  /// Param: [AnalyticsParams.formMode] (`create` | `edit`).
  /// Max 40 chars: 'events_draft_saved'.length == 18. ✓
  static const String eventsDraftSaved = 'events_draft_saved';

  /// El rider publicó el evento exitosamente.
  /// Param: [AnalyticsParams.formMode] (`create` | `edit`).
  /// Max 40 chars: 'events_published'.length == 16. ✓
  static const String eventsPublished = 'events_published';

  /// El intento de publicar falló.
  /// Params: [AnalyticsParams.formMode], [AnalyticsParams.failureCategory].
  /// Max 40 chars: 'events_publish_failed'.length == 21. ✓
  static const String eventsPublishFailed = 'events_publish_failed';

  /// El rider inició el borrado de un evento.
  /// Max 40 chars: 'events_delete_attempted'.length == 23. ✓
  static const String eventsDeleteAttempted = 'events_delete_attempted';

  /// El evento se borró exitosamente.
  /// Max 40 chars: 'events_delete_succeeded'.length == 23. ✓
  static const String eventsDeleteSucceeded = 'events_delete_succeeded';

  /// El borrado del evento falló.
  /// Param: [AnalyticsParams.failureCategory].
  /// Max 40 chars: 'events_delete_failed'.length == 20. ✓
  static const String eventsDeleteFailed = 'events_delete_failed';

  // ---------------------------------------------------------------------------
  // Event registration — wizard (Fase 7)
  // ---------------------------------------------------------------------------

  /// El rider abrió el wizard de registro a un evento.
  /// Max 40 chars: 'registration_started'.length == 20. ✓
  static const String registrationStarted = 'registration_started';

  /// El rider avanzó al siguiente paso del wizard.
  /// Params: [AnalyticsParams.stepIndex], [AnalyticsParams.stepName].
  /// Max 40 chars: 'registration_step_advanced'.length == 26. ✓
  static const String registrationStepAdvanced = 'registration_step_advanced';

  /// El rider retrocedió al paso anterior del wizard.
  /// Params: [AnalyticsParams.stepIndex], [AnalyticsParams.stepName].
  /// Max 40 chars: 'registration_step_back'.length == 22. ✓
  static const String registrationStepBack = 'registration_step_back';

  /// El rider envió el registro exitosamente.
  /// Param: [AnalyticsParams.formMode] (`create` | `edit`).
  /// Max 40 chars: 'registration_submitted'.length == 22. ✓
  static const String registrationSubmitted = 'registration_submitted';

  /// El envío del registro falló.
  /// Params: [AnalyticsParams.formMode], [AnalyticsParams.failureCategory].
  /// Max 40 chars: 'registration_submit_failed'.length == 26. ✓
  static const String registrationSubmitFailed = 'registration_submit_failed';

  /// El rider cerró el wizard sin enviar (mejor esfuerzo — dispose).
  /// Max 40 chars: 'registration_abandoned'.length == 22. ✓
  static const String registrationAbandoned = 'registration_abandoned';

  // ---------------------------------------------------------------------------
  // Event registration — aprobación (Fase 7)
  // ---------------------------------------------------------------------------

  /// El organizador aprobó una inscripción.
  /// Max 40 chars: 'registration_approved'.length == 21. ✓
  static const String registrationApproved = 'registration_approved';

  /// El organizador rechazó una inscripción.
  /// Max 40 chars: 'registration_rejected'.length == 21. ✓
  static const String registrationRejected = 'registration_rejected';

  /// El organizador marcó la inscripción como "listo para editar".
  /// Max 40 chars: 'registration_ready_for_edit'.length == 27. ✓
  static const String registrationReadyForEdit = 'registration_ready_for_edit';

  /// Una acción de aprobación/rechazo/readyForEdit falló en el backend.
  /// Param: [AnalyticsParams.approvalAction].
  /// Max 40 chars: 'registration_approval_failed'.length == 28. ✓
  static const String registrationApprovalFailed =
      'registration_approval_failed';

  // ---------------------------------------------------------------------------
  // Event registration — mis registros (Fase 7)
  // ---------------------------------------------------------------------------

  /// El rider vio su listado de inscripciones propias.
  /// Max 40 chars: 'registration_my_list_viewed'.length == 27. ✓
  static const String registrationMyListViewed = 'registration_my_list_viewed';

  /// El rider canceló su propia inscripción exitosamente.
  /// Max 40 chars: 'registration_cancelled'.length == 22. ✓
  static const String registrationCancelled = 'registration_cancelled';
}
