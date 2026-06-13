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
  ///
  /// **Fase 4 (Insights de Producto — decisión explícita):** No se añaden
  /// eventos de auth nuevos en esta fase. Los call sites existentes en
  /// `login_view`, `signup_view`, `forgot_password_view`,
  /// `login_social_section` y `signup_social_buttons` cubren el embudo de
  /// adquisición sin extender el catálogo. Ver §3 "No entra" del PRD de Fase 4.
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

  /// Firebase Auth respondió OK (token válido). Se emite justo antes de llamar
  /// al API. Param: [AnalyticsParams.authMethod], [AnalyticsParams.userLoaded].
  /// Permite distinguir "Firebase falló" de "Firebase ok, API falló".
  /// Max 40 chars: 'auth_firebase_ok'.length == 16. ✓
  static const String authFirebaseOk = 'auth_firebase_ok';

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

  /// Intención de tap en publicar evento (antes del trabajo async).
  /// Max 40 chars: 'events_publish_attempted'.length == 24. ✓
  static const String eventsPublishAttempted = 'events_publish_attempted';

  /// El rider avanzó al siguiente paso del wizard de creación.
  /// Params: [AnalyticsParams.stepIndex], [AnalyticsParams.stepName].
  /// Max 40 chars: 'events_step_advanced'.length == 20. ✓
  static const String eventsStepAdvanced = 'events_step_advanced';

  /// El rider retrocedió al paso anterior del wizard de creación.
  /// Params: [AnalyticsParams.stepIndex], [AnalyticsParams.stepName].
  /// Max 40 chars: 'events_step_back'.length == 16. ✓
  static const String eventsStepBack = 'events_step_back';

  /// El rider cerró el wizard sin publicar ni guardar borrador.
  /// Params: [AnalyticsParams.formMode], [AnalyticsParams.abandonedAtStep].
  /// Max 40 chars: 'events_create_abandoned'.length == 23. ✓
  static const String eventsCreateAbandoned = 'events_create_abandoned';

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

  /// Intención de tap en enviar inscripción (antes del trabajo async).
  /// Max 40 chars: 'registration_submit_attempted'.length == 29. ✓
  static const String registrationSubmitAttempted =
      'registration_submit_attempted';

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

  // ---------------------------------------------------------------------------
  // Live tracking — hitos de sesión (Fase 8)
  //
  // PROHIBICIÓN: NUNCA emitir un evento por cada ping de ubicación
  // (_listenPosition / publishLocation) ni por cada mensaje WebSocket
  // entrante (_onMessage). Solo hitos de ciclo de vida por sesión.
  // Las coordenadas (latitude/longitude) NUNCA van como param.
  // ---------------------------------------------------------------------------

  /// El rider confirmó el arranque exitoso de su tracking (callback de éxito
  /// de StartTrackingUseCase). Se emite una sola vez por sesión.
  /// Param: [AnalyticsParams.trackingRole].
  /// Max 40 chars: 'tracking_session_started'.length == 24. ✓
  static const String trackingSessionStarted = 'tracking_session_started';

  /// El tracking se detuvo de forma efectiva (signOut, close o eventEnded).
  /// Se emite exactamente una vez por sesión (anti-doble-conteo vía flag).
  /// Param: [AnalyticsParams.trackingEndReason].
  /// Max 40 chars: 'tracking_session_ended'.length == 22. ✓
  static const String trackingSessionEnded = 'tracking_session_ended';

  /// El mapa se pobló por primera vez en la sesión activa (primer snapshot
  /// de riders recibido). Se emite una sola vez por sesión.
  /// Param: [AnalyticsParams.riderCount].
  /// Max 40 chars: 'tracking_snapshot_received'.length == 26. ✓
  static const String trackingSnapshotReceived = 'tracking_snapshot_received';

  // ---------------------------------------------------------------------------
  // SOS — hitos (Fase 8)
  //
  // PROHIBICIÓN: ningún param de SOS puede incluir coordenadas lat/lng,
  // uid de usuario, nombre, teléfono ni id de evento como valor.
  // ---------------------------------------------------------------------------

  /// El rider disparó un SOS propio (llamada a publishSos exitosa).
  /// Param: [AnalyticsParams.trackingRole].
  /// Max 40 chars: 'sos_activated'.length == 13. ✓
  static const String sosActivated = 'sos_activated';

  /// El sistema confirmó/propagó el SOS propio del rider (alerta recibida
  /// cuyo userId == _userId). Se emite una vez por activación de SOS.
  /// Sin params requeridos.
  /// Max 40 chars: 'sos_confirmed'.length == 13. ✓
  static const String sosConfirmed = 'sos_confirmed';

  /// El SOS propio fue cerrado/cancelado (local o remoto).
  /// Se emite una vez por activación (anti-doble-conteo vía flag).
  /// Param: [AnalyticsParams.sosClearReason].
  /// Max 40 chars: 'sos_cleared'.length == 11. ✓
  static const String sosCleared = 'sos_cleared';

  // ---------------------------------------------------------------------------
  // Vehículos (Fase 9)
  // ---------------------------------------------------------------------------

  /// El rider agregó un vehículo exitosamente.
  /// Param: [AnalyticsParams.hadPhoto] (0/1).
  /// Max 40 chars: 'vehicle_added'.length == 13. ✓
  static const String vehicleAdded = 'vehicle_added';

  /// El rider editó un vehículo exitosamente.
  /// Param: [AnalyticsParams.hadPhoto] (0/1).
  /// Max 40 chars: 'vehicle_updated'.length == 15. ✓
  static const String vehicleUpdated = 'vehicle_updated';

  /// El rider eliminó un vehículo exitosamente.
  /// Sin params PII.
  /// Max 40 chars: 'vehicle_deleted'.length == 15. ✓
  static const String vehicleDeleted = 'vehicle_deleted';

  /// El rider marcó un vehículo como principal exitosamente.
  /// Sin params PII.
  /// Max 40 chars: 'vehicle_set_main'.length == 16. ✓
  static const String vehicleSetMain = 'vehicle_set_main';

  // ---------------------------------------------------------------------------
  // Mantenimiento (Fase 9)
  // ---------------------------------------------------------------------------

  /// El rider guardó un registro de mantenimiento exitosamente.
  /// Params: [AnalyticsParams.maintenanceType], [AnalyticsParams.maintenanceMode].
  /// Max 40 chars: 'maintenance_added'.length == 17. ✓
  static const String maintenanceAdded = 'maintenance_added';

  /// El rider vio el historial de mantenimientos tras una carga real.
  /// Param: [AnalyticsParams.resultCount].
  /// Max 40 chars: 'maintenance_history_viewed'.length == 26. ✓
  static const String maintenanceHistoryViewed = 'maintenance_history_viewed';

  /// El rider actualizó un mantenimiento existente (edición exitosa).
  /// Params: [AnalyticsParams.maintenanceType], [AnalyticsParams.maintenanceMode].
  /// Max 40 chars: 'maintenance_updated'.length == 19. ✓
  static const String maintenanceUpdated = 'maintenance_updated';

  /// El rider eliminó un mantenimiento (borrado exitoso).
  /// Param: [AnalyticsParams.maintenanceType].
  /// Max 40 chars: 'maintenance_deleted'.length == 19. ✓
  static const String maintenanceDeleted = 'maintenance_deleted';

  // ---------------------------------------------------------------------------
  // SOAT (Fase 9)
  // ---------------------------------------------------------------------------

  /// El rider vio el estado de un SOAT existente (load resolvió a Data).
  /// Param: [AnalyticsParams.soatStatus].
  /// Max 40 chars: 'soat_status_viewed'.length == 18. ✓
  static const String soatStatusViewed = 'soat_status_viewed';

  /// El rider guardó un SOAT manualmente (save confirmado).
  /// Params: [AnalyticsParams.hadPdf] (0/1), [AnalyticsParams.fieldsExtractedCount].
  /// Max 40 chars: 'soat_manual_saved'.length == 17. ✓
  static const String soatManualSaved = 'soat_manual_saved';

  /// El rider actualizó un SOAT existente (save sobre un SOAT con id).
  /// Param: [AnalyticsParams.hadPdf] (0/1).
  /// Max 40 chars: 'soat_updated'.length == 12. ✓
  static const String soatUpdated = 'soat_updated';

  /// El rider eliminó el SOAT de un vehículo (borrado exitoso).
  /// Sin PII en params.
  /// Max 40 chars: 'soat_deleted'.length == 12. ✓
  static const String soatDeleted = 'soat_deleted';

  // ---------------------------------------------------------------------------
  // Tecnomecánica (RTM)
  // ---------------------------------------------------------------------------

  /// El rider vio el estado de una RTM existente (load resolvió a Data).
  /// Param: [AnalyticsParams.rtmStatus].
  /// Max 40 chars: 'tecnomecanica_status_viewed'.length == 27. ✓
  static const String tecnomecanicaStatusViewed = 'tecnomecanica_status_viewed';

  /// El rider guardó una RTM manualmente (save confirmado, nuevo).
  /// Max 40 chars: 'tecnomecanica_manual_saved'.length == 26. ✓
  static const String tecnomecanicaManualSaved = 'tecnomecanica_manual_saved';

  /// El rider actualizó una RTM existente (save sobre RTM con id).
  /// Max 40 chars: 'tecnomecanica_updated'.length == 21. ✓
  static const String tecnomecanicaUpdated = 'tecnomecanica_updated';

  /// El rider eliminó la RTM de un vehículo (borrado exitoso).
  /// Max 40 chars: 'tecnomecanica_deleted'.length == 21. ✓
  static const String tecnomecanicaDeleted = 'tecnomecanica_deleted';

  // ---------------------------------------------------------------------------
  // Perfil (Fase 9)
  // ---------------------------------------------------------------------------

  /// El rider cargó su propio perfil exitosamente.
  /// Sin PII en params.
  /// Max 40 chars: 'profile_viewed'.length == 14. ✓
  static const String profileViewed = 'profile_viewed';

  /// El rider abrió el flujo de edición de su perfil.
  /// Sin params.
  /// Max 40 chars: 'profile_edit_started'.length == 20. ✓
  static const String profileEditStarted = 'profile_edit_started';

  /// El rider completó la edición de su perfil exitosamente.
  /// Sin PII en params.
  /// Max 40 chars: 'profile_edit_succeeded'.length == 22. ✓
  static const String profileEditSucceeded = 'profile_edit_succeeded';

  // ---------------------------------------------------------------------------
  // Users / descubrimiento (Fase 9)
  // ---------------------------------------------------------------------------

  /// El rider vio el perfil de otro rider tras una carga real.
  /// Sin PII: nunca userId del rider visitado como param.
  /// Max 40 chars: 'rider_profile_viewed'.length == 20. ✓
  static const String riderProfileViewed = 'rider_profile_viewed';

  // ---------------------------------------------------------------------------
  // AI — Asistentes IA (Fase 6)
  // ---------------------------------------------------------------------------

  /// El asistente de descripción generó una respuesta exitosa.
  /// Param: [AnalyticsParams.aiTurnIndex] (índice 1-based del turno modelo en la historia).
  /// Max 40 chars: 'ai_description_generated'.length == 24. ✓
  static const String aiDescriptionGenerated = 'ai_description_generated';

  /// Se agotó la cuota del usuario o del proyecto al intentar generar.
  /// Params: [AnalyticsParams.aiGenerationType], [AnalyticsParams.aiErrorCode].
  /// Max 40 chars: 'ai_quota_exceeded'.length == 17. ✓
  static const String aiQuotaExceeded = 'ai_quota_exceeded';

  /// La generación IA falló por un error recuperable (red, safety filter, etc.).
  /// Params: [AnalyticsParams.aiGenerationType], [AnalyticsParams.aiErrorCode].
  /// Max 40 chars: 'ai_generation_failed'.length == 20. ✓
  static const String aiGenerationFailed = 'ai_generation_failed';

  // ---------------------------------------------------------------------------
  // Notificaciones (Fase 9)
  // ---------------------------------------------------------------------------

  /// El rider abrió/marcó leída una notificación específica.
  /// Sin id de notificación ni texto del mensaje como param.
  /// Param: [AnalyticsParams.notificationType].
  /// Max 40 chars: 'notification_marked_read'.length == 24. ✓
  static const String notificationMarkedRead = 'notification_marked_read';

  /// El rider marcó todas las notificaciones como leídas.
  /// Sin params.
  /// Max 40 chars: 'notifications_all_read'.length == 22. ✓
  static const String notificationsAllRead = 'notifications_all_read';

  /// Se registró el token FCM del dispositivo (señal de salud).
  /// Sin el token como param (PII/alta cardinalidad).
  /// Max 40 chars: 'fcm_token_registered'.length == 20. ✓
  static const String fcmTokenRegistered = 'fcm_token_registered';

  // ---------------------------------------------------------------------------
  // Home — CTAs de navegación
  // ---------------------------------------------------------------------------

  /// Tap en CTA "Ver eventos" en la tarjeta de home vacía (navegación pura).
  /// Max 40 chars: 'home_empty_events_cta'.length == 21. ✓
  static const String homeEmptyEventsCta = 'home_empty_events_cta';
}
