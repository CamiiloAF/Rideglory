// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Rideglory';

  @override
  String get accept => 'Aceptar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Agregar';

  @override
  String get apply => 'Aplicar';

  @override
  String get clear => 'Limpiar';

  @override
  String get retry => 'Reintentar';

  @override
  String get back => 'Volver';

  @override
  String get continue_ => 'Continuar';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get generateWithAI => 'Generar con IA';

  @override
  String get photoPermissionTitle => 'Permiso de galería';

  @override
  String get photoPermissionDenied =>
      'Se necesita acceso a la galería para elegir una imagen.';

  @override
  String get photoPermissionPermanentlyDenied =>
      'El acceso a la galería está desactivado. Actívalo en Ajustes para subir una imagen.';

  @override
  String get exit => 'Salir';

  @override
  String get exitAppTitle => 'Salir de la aplicación';

  @override
  String get exitAppMessage =>
      '¿Estás seguro de que deseas salir de Rideglory?';

  @override
  String get errorOccurred => 'Ocurrió un error';

  @override
  String get tryAgain => 'Intentar nuevamente';

  @override
  String get noInternet => 'Sin conexión a internet';

  @override
  String get locationPermissionTitle => 'Permiso de ubicación';

  @override
  String get locationPermissionMapRequiredMessage =>
      'Necesitamos acceso a tu ubicación para mostrar tu posición y seguir la rodada en vivo. Puedes continuar usando la app sin este permiso, pero el mapa en vivo no estará disponible.';

  @override
  String get imageUploadFailed =>
      'No se pudo subir la imagen. Revisa tu conexión e intenta de nuevo.';

  @override
  String get imageUploadCancelled => 'La subida de la imagen fue cancelada.';

  @override
  String get imageUploadNotFound =>
      'No se pudo completar la subida. Intenta de nuevo en unos segundos.';

  @override
  String get noData => 'No hay datos';

  @override
  String get noResults => 'No se encontraron resultados';

  @override
  String get noSearchResultsHint => 'Intenta ajustar los filtros o la búsqueda';

  @override
  String get notAvailable => 'N/A';

  @override
  String get noSearchResults => 'No se encontraron resultados para tu búsqueda';

  @override
  String get loading => 'Cargando...';

  @override
  String get pleaseWait => 'Por favor espera';

  @override
  String get success => 'Éxito';

  @override
  String get savedSuccessfully => 'Guardado exitosamente';

  @override
  String get deletedSuccessfully => 'Eliminado exitosamente';

  @override
  String get updatedSuccessfully => 'Actualizado exitosamente';

  @override
  String get settings => 'Configuración';

  @override
  String get comingSoon => 'próximamente';

  @override
  String get required => 'es requerido';

  @override
  String get mustBeNumber => 'Debe ser un número';

  @override
  String get invalidValue => 'Valor inválido';

  @override
  String get mustBeGreaterThanZero => 'Debe ser mayor a 0';

  @override
  String get mustBeGreaterThan => 'Debe ser mayor a';

  @override
  String errorMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get auth_loginTitle => 'Bienvenido';

  @override
  String get auth_loginSubtitleStitch => 'Acelera tu experiencia';

  @override
  String get auth_emailLabel => 'Correo electrónico';

  @override
  String get auth_emailHint => 'nombre@ejemplo.com';

  @override
  String get auth_passwordLabel => 'Contraseña';

  @override
  String get auth_passwordHint => 'Mínimo 8 caracteres';

  @override
  String get auth_forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get auth_signInButton => 'Iniciar sesión';

  @override
  String get auth_orContinueWithStitch => 'O continúa con';

  @override
  String get auth_noAccountQuestion => '¿No tienes una cuenta?';

  @override
  String get auth_registerFreeLink => 'Regístrate gratis';

  @override
  String get auth_googleLabel => 'Google';

  @override
  String get auth_appleLabel => 'Apple';

  @override
  String get auth_signingInLabel => 'Iniciando sesión...';

  @override
  String get auth_registerTitle => 'Únete a la comunidad';

  @override
  String get auth_registerSubtitle =>
      'Crea tu cuenta para empezar a rodar con nosotros.';

  @override
  String get auth_registerSignInQuestion => '¿Ya tienes una cuenta?';

  @override
  String get auth_registerSignInLink => 'Inicia sesión';

  @override
  String get auth_nameField => 'Nombre completo';

  @override
  String get auth_nameHint => 'Ej. Juan Pérez';

  @override
  String get auth_passwordMinStitch => 'Mínimo 8 caracteres';

  @override
  String get auth_createAccountButton => 'Crear cuenta';

  @override
  String get auth_termsPrefix => 'Acepto los ';

  @override
  String get auth_termsOf => 'Términos';

  @override
  String get auth_termsAnd => ' y ';

  @override
  String get auth_termsConditions => 'Condiciones';

  @override
  String get auth_termsAnd2 => ' y la ';

  @override
  String get auth_termsPrivacy => 'Política de Privacidad';

  @override
  String get auth_termsSuffix => ' de MotoConnect.';

  @override
  String get auth_letsStart => 'Comencemos';

  @override
  String get auth_loginSubtitle =>
      'Inicia sesión o crea una cuenta para gestionar tus vehículos';

  @override
  String get auth_signIn => 'Ingresar';

  @override
  String get auth_signUp => 'Registrarse';

  @override
  String get auth_createAccount => 'Crear Cuenta';

  @override
  String get auth_joinToday => 'Únete Hoy';

  @override
  String get auth_signupSubtitleSocial => 'Elige cómo crear tu cuenta';

  @override
  String get auth_signupSubtitleEmail =>
      'Crea tu cuenta con email y contraseña';

  @override
  String get auth_alreadyHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get auth_dontHaveAccount => '¿No tienes cuenta?';

  @override
  String get auth_signUpHere => 'Regístrate aquí';

  @override
  String get auth_signInHere => 'Inicia sesión aquí';

  @override
  String get auth_createAccountLink => 'Crear una';

  @override
  String get auth_signInLink => 'aquí';

  @override
  String get auth_orContinueWith => 'O continúa con';

  @override
  String get auth_email => 'Correo electrónico';

  @override
  String get auth_password => 'Contraseña';

  @override
  String get auth_confirmPassword => 'Confirmar contraseña';

  @override
  String get auth_enterEmail => 'Ingrese su correo electrónico';

  @override
  String get auth_enterPassword => 'Ingresa tu contraseña';

  @override
  String get auth_createPassword => 'Crea una contraseña';

  @override
  String get auth_confirmYourPassword => 'Confirma tu contraseña';

  @override
  String get auth_emailRequired => 'El email es requerido';

  @override
  String get auth_invalidEmail => 'Dirección de correo inválida';

  @override
  String get auth_passwordRequired => 'La contraseña es requerida';

  @override
  String get auth_passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get auth_passwordMinLength8 =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get auth_passwordNeedsUppercase =>
      'La contraseña debe contener una mayúscula';

  @override
  String get auth_passwordNeedsNumber =>
      'La contraseña debe contener un número';

  @override
  String get auth_confirmPasswordRequired => 'Por favor confirma tu contraseña';

  @override
  String get auth_passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get auth_continueWithEmail => 'Continuar con correo';

  @override
  String get auth_continueWithGoogle => 'Continuar con Google';

  @override
  String get auth_continueWithApple => 'Continuar con Apple';

  @override
  String get auth_acceptTerms => 'Acepto los ';

  @override
  String get auth_termsOfService => 'Términos de Servicio';

  @override
  String get auth_privacyPolicy => 'Política de Privacidad';

  @override
  String get auth_termsAndConditions => 'términos y condiciones';

  @override
  String get auth_acceptTermsError =>
      'Por favor acepta los términos y condiciones';

  @override
  String get auth_failedToSignOut => 'Falló al cerrar sesión, intenta de nuevo';

  @override
  String get auth_logout => 'Cerrar sesión';

  @override
  String get auth_logoutConfirmTitle => 'Cerrar sesión';

  @override
  String get auth_logoutConfirmMessage =>
      '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get auth_exitLoginTitle => 'Salir del inicio de sesión';

  @override
  String get auth_exitLoginMessage => '¿Estás seguro de que deseas salir?';

  @override
  String get event_events => 'Eventos';

  @override
  String get event_myEvents => 'Mis Eventos';

  @override
  String get event_createEvent => 'Crear Evento';

  @override
  String get event_editEvent => 'Editar Evento';

  @override
  String get event_eventDetail => 'Detalle del Evento';

  @override
  String get event_deleteEvent => 'Eliminar Evento';

  @override
  String get event_edit => 'Editar';

  @override
  String get event_delete => 'Eliminar';

  @override
  String get event_meetingTimePrefix => 'Encuentro: ';

  @override
  String get event_allBrands => 'Todas las marcas';

  @override
  String get event_basicInfo => 'Información básica';

  @override
  String get event_dateAndTime => 'Fecha y hora';

  @override
  String get event_locations => 'Ubicaciones';

  @override
  String get event_eventDetails => 'Detalles del evento';

  @override
  String get event_eventName => 'Nombre del evento';

  @override
  String get event_eventDescription => 'Descripción';

  @override
  String get event_eventCity => 'Ciudad';

  @override
  String get event_eventCityHint => 'Buscar ciudad y departamento...';

  @override
  String get event_startDate => 'Fecha de inicio';

  @override
  String get event_eventNameHint => 'Ej: Rodada de la semana';

  @override
  String get event_eventNameCannotBeModified =>
      'El nombre del evento no se puede modificar una vez creado.';

  @override
  String get event_endDate => 'Fecha de fin (opcional)';

  @override
  String get event_dateRange => 'Rango de fechas del evento';

  @override
  String get event_isMultiDay => 'Es un evento de varios días';

  @override
  String get event_meetingTime => 'Hora de encuentro';

  @override
  String get event_difficulty => 'Dificultad';

  @override
  String get event_rideDifficulty => 'Dificultad de la Ruta';

  @override
  String get event_eventType => 'Tipo de evento';

  @override
  String get event_finalDestination => 'Destino final';

  @override
  String get event_searchBrandsPlaceholder => 'Escribe para buscar marcas...';

  @override
  String get event_meetingPoint => 'Punto de encuentro';

  @override
  String get event_meetingPointHint => 'Ej: Parque principal, Cra 5 #10-20';

  @override
  String get event_meetingPointLocation => 'Ubicación del punto de encuentro';

  @override
  String get event_destination => 'Destino';

  @override
  String get event_latitude => 'Latitud';

  @override
  String get event_longitude => 'Longitud';

  @override
  String get event_isMultiBrand => 'Evento multimarca (abierto a todos)';

  @override
  String get event_allowedBrands => 'Marcas permitidas';

  @override
  String get event_allowedBrandsHint => 'Honda, Yamaha, Kawasaki...';

  @override
  String get event_allowedBrandsHelper =>
      'Separar con coma. Dejar vacío si acepta todas las marcas.';

  @override
  String get event_addBrand => 'Agregar marca';

  @override
  String get event_price => 'Precio del evento (opcional)';

  @override
  String get event_priceHint => '0 para evento gratuito';

  @override
  String get event_freeEvent => 'Evento gratuito';

  @override
  String get event_startDateMustBeBeforeEndDate =>
      'La fecha de inicio debe ser anterior a la fecha de fin';

  @override
  String get event_difficultyOne => 'Fácil';

  @override
  String get event_difficultyTwo => 'Moderado';

  @override
  String get event_difficultyThree => 'Intermedio';

  @override
  String get event_difficultyFour => 'Difícil';

  @override
  String get event_difficultyFive => 'Muy difícil';

  @override
  String get event_offRoad => 'Off-Road';

  @override
  String get event_onRoad => 'On-Road';

  @override
  String get event_exhibition => 'Exhibición';

  @override
  String get event_charitable => 'Benéfico';

  @override
  String get event_saveEvent => 'Guardar Evento';

  @override
  String get event_updateEvent => 'Actualizar Evento';

  @override
  String get event_publishEvent => 'Publicar evento';

  @override
  String get event_newEvent => 'Nuevo evento';

  @override
  String get event_publish => 'Publicar';

  @override
  String get event_aiSuggestDescription => 'Sugerir con IA';

  @override
  String get event_addEventCover => 'Agregar portada del evento';

  @override
  String get event_addEventCoverHint =>
      'Una imagen impactante atrae a más motociclistas. Formatos: JPG, PNG.';

  @override
  String get event_uploadImage => 'Subir imagen';

  @override
  String get event_generateWithAI => 'Generar';

  @override
  String get event_photoPermissionDenied =>
      'Se necesita acceso a la galería para elegir la portada del evento.';

  @override
  String get event_photoPermissionPermanentlyDenied =>
      'El acceso a la galería está desactivado. Actívalo en Ajustes para subir una imagen.';

  @override
  String get event_openSettings => 'Abrir ajustes';

  @override
  String get event_pickImageError => 'No se pudo seleccionar la imagen.';

  @override
  String get event_originCity => 'Ciudad de origen';

  @override
  String get event_dateRangeLabel => 'Fecha (rango)';

  @override
  String get event_routeAndMap => 'Ruta y mapa';

  @override
  String get event_meetingPointPreview => 'Vista previa del punto de encuentro';

  @override
  String get event_viewOnMap => 'Ver en mapa';

  @override
  String get event_multiBrandLabel => 'Multimarca';

  @override
  String get event_multiBrandAllowAny =>
      'Permitir motos de cualquier fabricante';

  @override
  String get event_selectBrands => 'Seleccionar marcas permitidas';

  @override
  String get event_registrationPriceOptional =>
      'Precio de inscripción (opcional)';

  @override
  String get event_descriptionAndRecommendations =>
      'Descripción y recomendaciones';

  @override
  String get event_descriptionHint =>
      'Cuéntanos de qué trata esta rodada, el ritmo, qué equipo llevar y qué esperar...';

  @override
  String get event_eventCreatedSuccess => 'Evento creado exitosamente';

  @override
  String get event_eventUpdatedSuccess => 'Evento actualizado exitosamente';

  @override
  String get event_eventDeletedSuccess => 'Evento eliminado exitosamente';

  @override
  String get event_deleteEventMessage =>
      '¿Estás seguro de que deseas eliminar este evento?\nEsta acción no se puede deshacer.';

  @override
  String get event_noEvents => 'No hay eventos disponibles';

  @override
  String get event_noEventsDescription =>
      'Sé el primero en crear un evento para la comunidad';

  @override
  String get event_noMyEvents => 'No has creado eventos';

  @override
  String get event_noMyEventsDescription =>
      'Crea tu primer evento y compártelo con la comunidad';

  @override
  String get event_searchEvents => 'Buscar eventos';

  @override
  String get event_filters => 'Filtros';

  @override
  String get event_applyFilters => 'Aplicar filtros';

  @override
  String get event_clearFilters => 'Limpiar filtros';

  @override
  String get event_filterAll => 'Todos';

  @override
  String get event_searchRegistrations => 'Buscar inscripciones';

  @override
  String get event_filterByType => 'Tipo de evento';

  @override
  String get event_filterByDifficulty => 'Dificultad';

  @override
  String get event_filterByCity => 'Ciudad';

  @override
  String get event_filterByDateRange => 'Rango de fechas';

  @override
  String get event_filterByFreeOnly => 'Solo eventos gratuitos';

  @override
  String get event_filterByMultiBrand => 'Solo multimarca';

  @override
  String get event_filterByStatus => 'Estado';

  @override
  String get event_aboutTheRide => 'Sobre la rodada';

  @override
  String get event_organizedBy => 'Organizado por';

  @override
  String get event_organizerPlaceholder => 'el creador';

  @override
  String get event_totalParticipation => 'Total participación';

  @override
  String get event_registerMe => 'Inscribirme';

  @override
  String get event_viewMap => 'Ver mapa';

  @override
  String get event_creatorRecommendations => 'RECOMENDACIONES DEL CREADOR';

  @override
  String get event_allowedBrandsTitle => 'Marcas Permitidas';

  @override
  String get event_allBrandsChip => '+ Todas';

  @override
  String get event_comingSoonPill => 'PRÓXIMAMENTE';

  @override
  String get event_joinEvent => 'Inscribirse';

  @override
  String get event_editRegistration => 'Editar inscripción';

  @override
  String get event_cancelRegistration => 'Cancelar inscripción';

  @override
  String get event_viewRecommendations => 'Ver recomendaciones';

  @override
  String get event_viewAttendees => 'Ver inscritos';

  @override
  String get event_openInMaps => 'Abrir en Google Maps';

  @override
  String get event_meetingPointLabel => 'Punto de encuentro';

  @override
  String get event_destinationLabel => 'Destino';

  @override
  String get event_comingSoon => 'Próximamente';

  @override
  String get event_eventLiveNow => 'EN VIVO';

  @override
  String get event_eventHasStartedTitle => 'Evento en curso';

  @override
  String get event_eventHasStartedDescription =>
      'La rodada ha comenzado. Sigue la ubicación en tiempo real de todos los participantes y no te pierdas nada.';

  @override
  String get event_followRideLive => 'Seguir rodada en vivo';

  @override
  String get event_eventFinished => 'Finalizado';

  @override
  String get event_dateLabel => 'Fecha';

  @override
  String get event_priceLabel => 'Precio';

  @override
  String get event_free => 'Gratuito';

  @override
  String get event_eventCardPriceFree => 'Gratis';

  @override
  String get event_eventCardMyEvent => 'Mi evento';

  @override
  String get event_difficultyLabel => 'Dificultad';

  @override
  String get event_typeLabel => 'Tipo';

  @override
  String get event_organizer => 'Organizador';

  @override
  String get event_brandRestriction => 'Marcas';

  @override
  String get event_openToAllBrands => 'Abierto a todos';

  @override
  String get event_pending => 'Pendiente';

  @override
  String get event_approved => 'Aprobado';

  @override
  String get event_rejected => 'Rechazado';

  @override
  String get event_cancelled => 'Cancelado';

  @override
  String get event_readyForEdit => 'Listo para editar';

  @override
  String get event_pendingDescription =>
      'Tu inscripción está pendiente de aprobación';

  @override
  String get event_approvedDescription => '¡Tu inscripción fue aprobada!';

  @override
  String get event_rejectedDescription =>
      'Tu inscripción fue rechazada. No puedes volver a inscribirte a este evento.';

  @override
  String get event_cancelledDescription => 'Cancelaste tu inscripción.';

  @override
  String get event_readyForEditDescription =>
      'El organizador habilitó la edición de tu inscripción.';

  @override
  String get event_attendees => 'Inscritos';

  @override
  String get event_participants => 'Participantes';

  @override
  String get event_attendeesCount => 'personas inscritas';

  @override
  String get event_approveRegistration => 'Aprobar';

  @override
  String get event_rejectRegistration => 'Rechazar';

  @override
  String get event_setReadyForEdit => 'Habilitar edición';

  @override
  String get event_contactAttendee => 'Contactar';

  @override
  String get event_callAttendee => 'Llamar';

  @override
  String get event_emailAttendee => 'Enviar correo';

  @override
  String get event_whatsappAttendee => 'WhatsApp';

  @override
  String get event_noAttendees => 'No hay inscritos aún';

  @override
  String get event_newRequestsSection => 'NUEVAS SOLICITUDES';

  @override
  String get event_pendingBadgeSuffix => 'PENDIENTES';

  @override
  String get event_processedSection => 'YA PROCESADOS';

  @override
  String get event_allProcessed => 'Todos';

  @override
  String get event_approvedBadge => 'APROBADO';

  @override
  String get event_rejectedBadge => 'RECHAZADO';

  @override
  String get event_searchAttendees => 'Buscar participantes';

  @override
  String get event_filterAttendees => 'Filtrar participantes';

  @override
  String get event_cancelRegistrationTitle => 'Cancelar inscripción';

  @override
  String get event_cancelRegistrationMessage =>
      '¿Estás seguro de que deseas cancelar tu inscripción? Esta acción no se puede deshacer. Podrás inscribirte nuevamente en cualquier momento.';

  @override
  String get event_cancelRegistrationSuccess =>
      'Tu inscripción fue cancelada exitosamente';

  @override
  String get event_errorLoadingEvents => 'Error al cargar los eventos';

  @override
  String get event_errorSavingEvent => 'Error al guardar el evento';

  @override
  String get event_errorDeletingEvent => 'Error al eliminar el evento';

  @override
  String get event_nameRequired => 'El nombre es requerido';

  @override
  String get event_descriptionRequired => 'La descripción es requerida';

  @override
  String get event_cityRequired => 'La ciudad es requerida';

  @override
  String get event_dateRangeRequired => 'Las fechas del evento son requeridas';

  @override
  String get event_startDateRequired => 'La fecha de inicio es requerida';

  @override
  String get event_meetingTimeRequired => 'La hora de encuentro es requerida';

  @override
  String get event_meetingPointRequired => 'El punto de encuentro es requerido';

  @override
  String get event_destinationRequired => 'El destino es requerido';

  @override
  String get event_difficultyRequired => 'La dificultad es requerida';

  @override
  String get event_eventTypeRequired => 'El tipo de evento es requerido';

  @override
  String get event_minCharacters => 'Mínimo 3 caracteres';

  @override
  String get event_invalidLatitude => 'Latitud inválida (-90 a 90)';

  @override
  String get event_invalidLongitude => 'Longitud inválida (-180 a 180)';

  @override
  String get event_invalidPrice => 'Precio inválido';

  @override
  String get map_liveTrackingTitle => 'Rider Telemetry & Map';

  @override
  String get map_rideLabelPrefix => 'Rodada: ';

  @override
  String get map_activeRidersChip => 'Activos:';

  @override
  String get map_riderTelemetry => 'Rider telemetry';

  @override
  String get map_participantsList => 'Lista de participantes';

  @override
  String get map_participantsPlaceholder =>
      'Participant List (placeholder)\n\nImplementación próximamente.';

  @override
  String get map_speed => 'Velocidad';

  @override
  String get map_distance => 'Distancia';

  @override
  String get map_battery => 'Batería';

  @override
  String get map_sos => 'SOS';

  @override
  String get map_riderLead => 'Lead';

  @override
  String get map_riderRole => 'Rider';

  @override
  String get map_mockRiderAlex => 'Alex';

  @override
  String get map_mockRiderMarkThompson => 'Mark Thompson';

  @override
  String get map_mockRiderSarahJenkins => 'Sarah Jenkins';

  @override
  String get map_mockDeviceGarmin1040 => 'Garmin Edge 1040';

  @override
  String get map_mockDeviceGarmin530 => 'Garmin Edge 530';

  @override
  String get map_mockDeviceWahooElemnt => 'Wahoo ELEMNT';

  @override
  String get maintenance_maintenance => 'Mantenimiento';

  @override
  String get maintenance_maintenances => 'Mantenimientos';

  @override
  String get maintenance_addMaintenance => 'Agregar mantenimiento';

  @override
  String get maintenance_editMaintenance => 'Editar mantenimiento';

  @override
  String get maintenance_deleteMaintenance => 'Eliminar mantenimiento';

  @override
  String get maintenance_maintenanceHistory => 'Ver historial';

  @override
  String get maintenance_reminders => 'Recordatorios';

  @override
  String get maintenance_maintenanceDetail => 'Detalle de mantenimiento';

  @override
  String get maintenance_newRecord => 'Nuevo Registro';

  @override
  String get maintenance_editRecord => 'Editar Registro';

  @override
  String get maintenance_deleteMaintenanceMessage =>
      '¿Estás seguro de que deseas eliminar este mantenimiento?\nEsta acción no se puede deshacer.';

  @override
  String get maintenance_noMaintenances => 'No hay mantenimientos registrados';

  @override
  String get maintenance_noMaintenancesDescription =>
      'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo';

  @override
  String get maintenance_receiveMaintenanceAlert =>
      'Recibe una notificación cuando se acerque el próximo mantenimiento';

  @override
  String get maintenance_mileageAlert => 'Alerta por kilometraje';

  @override
  String get maintenance_mileageAlertHint =>
      'Notificar cuando falten 500 km para el mantenimiento';

  @override
  String get maintenance_dateAlert => 'Alerta por fecha';

  @override
  String get maintenance_dateAlertHint =>
      'Notificar una semana antes de la fecha programada';

  @override
  String get maintenance_maintenanceDeletedSuccessfully =>
      'Mantenimiento eliminado correctamente';

  @override
  String get maintenance_errorLoadingRecords => 'Error cargando registros';

  @override
  String get maintenance_noRecordsYet => 'Aún no hay registros';

  @override
  String get maintenance_maintenanceType => 'Tipo de Mantenimiento';

  @override
  String get maintenance_maintenanceDate => 'Fecha de Mantenimiento';

  @override
  String get maintenance_maintenanceNotes => 'Notas / Observaciones';

  @override
  String get maintenance_maintenanceCost => 'Costo del Mantenimiento';

  @override
  String get maintenance_maintenanceMileage => 'Kilometraje Actual';

  @override
  String get maintenance_nextMaintenance => 'Próximo mantenimiento';

  @override
  String get maintenance_nextMaintenanceMileage =>
      'Kilometraje del próximo mantenimiento';

  @override
  String get maintenance_totalCost => 'Costo total';

  @override
  String get maintenance_serviceNotes => 'Notas de servicio';

  @override
  String get maintenance_estimatedDate => 'Fecha estimada';

  @override
  String get maintenance_suggested => 'Sugerido';

  @override
  String get maintenance_routine => 'Rutina';

  @override
  String get maintenance_alertByMileage => 'Por kilometraje';

  @override
  String get maintenance_alertByDate => 'Por fecha';

  @override
  String get maintenance_mileageAlertBefore => '500 km antes';

  @override
  String get maintenance_dateAlertBefore => '7 días antes';

  @override
  String get maintenance_urgent => 'Urgente';

  @override
  String get maintenance_urgentOnly => 'Solo urgentes';

  @override
  String get maintenance_filters => 'Filtros';

  @override
  String get maintenance_myVehicles => 'Mis Vehículos';

  @override
  String get maintenance_applyFilters => 'Aplicar filtros';

  @override
  String get maintenance_clearFilters => 'Limpiar filtros';

  @override
  String get maintenance_mileage => 'Kilometraje';

  @override
  String get maintenance_currentMileage => 'Kilometraje Actual';

  @override
  String get maintenance_updateMileage => 'Actualizar kilometraje';

  @override
  String get maintenance_mileageUnit => 'Unidad';

  @override
  String get maintenance_kilometers => 'Kilómetros';

  @override
  String get maintenance_miles => 'Millas';

  @override
  String get maintenance_km => 'km';

  @override
  String get maintenance_mi => 'mi';

  @override
  String get maintenance_current => 'Actual:';

  @override
  String get maintenance_maintenanceLabel => 'Mantenimiento:';

  @override
  String get maintenance_mileageGreaterThanCurrent =>
      'El kilometraje del mantenimiento es mayor al kilometraje actual del vehículo.';

  @override
  String get maintenance_updateVehicleMileageQuestion =>
      '¿Deseas actualizar el kilometraje del vehículo?';

  @override
  String get maintenance_monthJan => 'Ene';

  @override
  String get maintenance_monthFeb => 'Feb';

  @override
  String get maintenance_monthMar => 'Mar';

  @override
  String get maintenance_monthApr => 'Abr';

  @override
  String get maintenance_monthMay => 'May';

  @override
  String get maintenance_monthJun => 'Jun';

  @override
  String get maintenance_monthJul => 'Jul';

  @override
  String get maintenance_monthAug => 'Ago';

  @override
  String get maintenance_monthSep => 'Sep';

  @override
  String get maintenance_monthOct => 'Oct';

  @override
  String get maintenance_monthNov => 'Nov';

  @override
  String get maintenance_monthDec => 'Dic';

  @override
  String get maintenance_addMaintenance_ => 'Agregar mantenimiento';

  @override
  String get maintenance_addMaintenanceAction => 'Agregar mantenimiento';

  @override
  String get maintenance_viewHistory => 'Ver historial';

  @override
  String get maintenance_saveMaintenance => 'Guardar Registro';

  @override
  String get maintenance_saveOnly => 'Solo guardar';

  @override
  String get maintenance_update => 'Actualizar';

  @override
  String get maintenance_sortBy => 'Ordenar por';

  @override
  String get maintenance_maintenanceTypes => 'Tipos de mantenimiento';

  @override
  String get maintenance_vehicles => 'Vehículos';

  @override
  String get maintenance_dateRange => 'Rango de fechas';

  @override
  String get maintenance_startDate => 'Inicio';

  @override
  String get maintenance_endDate => 'Fin';

  @override
  String get maintenance_sortByNextMaintenance => 'Próximo mantenimiento';

  @override
  String get maintenance_sortByDate => 'Fecha de realización';

  @override
  String get maintenance_sortByName => 'Nombre';

  @override
  String get maintenance_urgentOnlyDescription =>
      'Próximo mantenimiento en 7 días o menos';

  @override
  String get maintenance_vehicle => 'Vehículo';

  @override
  String get maintenance_selectVehicle => 'Seleccionar Vehículo';

  @override
  String get maintenance_chooseVehicleForMaintenance =>
      'Elige el vehículo para este mantenimiento';

  @override
  String get maintenance_next => 'Próximo';

  @override
  String get maintenance_calculateRemainingDistance =>
      'Calcular distancia restante';

  @override
  String get maintenance_maintenanceName => 'Nombre del Mantenimiento';

  @override
  String get maintenance_nextMaintenanceDate => 'PRÓXIMA FECHA';

  @override
  String get maintenance_maintenanceDateLabel => 'Fecha de Servicio';

  @override
  String get maintenance_nextMaintenanceMileageLabel => 'PRÓXIMO KM';

  @override
  String get maintenance_nameRequired => 'El nombre es requerido';

  @override
  String get maintenance_minCharacters => 'Mínimo 3 caracteres';

  @override
  String get maintenance_typeRequired => 'El tipo es requerido';

  @override
  String get maintenance_remindersLabel => 'Recibe recordatorios automáticos';

  @override
  String get maintenance_nextServiceAlerts => 'Alertas de próximo servicio';

  @override
  String get maintenance_alertsConfiguration => 'Configuración de alertas';

  @override
  String get maintenance_alertsActivatedDesc =>
      'Las alertas están activadas para este mantenimiento.';

  @override
  String get maintenance_searchMaintenances =>
      'Buscar por nombre del mantenimiento';

  @override
  String get maintenance_allVehicles => 'Todos los vehículos';

  @override
  String get maintenance_recentRecords => 'Registros recientes';

  @override
  String get maintenance_filter => 'Filtrar';

  @override
  String get vehicle_vehicles => 'Vehículos';

  @override
  String get vehicle_myVehicles => 'Mis Vehículos';

  @override
  String get vehicle_myGarage => 'Mi Garaje';

  @override
  String get vehicle_addVehicle => 'Agregar vehículo';

  @override
  String get vehicle_saveVehicle => 'Guardar vehículo';

  @override
  String get vehicle_editVehicle => 'Editar vehículo';

  @override
  String get vehicle_deleteVehicle => 'Eliminar vehículo';

  @override
  String get vehicle_addMaintenance => 'Agregar mantenimiento';

  @override
  String get vehicle_selectVehicle => 'Seleccionar vehículo';

  @override
  String get vehicle_changeVehicle => 'Cambiar vehículo';

  @override
  String get vehicle_setAsMainVehicle => 'Establecer como vehículo principal';

  @override
  String get vehicle_setAsMain => 'Establecer como principal';

  @override
  String get vehicle_archiveVehicle => 'Archivar';

  @override
  String get vehicle_unarchiveVehicle => 'Desarchivar';

  @override
  String get vehicle_deleteVehicleMessage =>
      '¿Estás seguro de que deseas eliminar';

  @override
  String get vehicle_deleteVehicleWarning =>
      'Esta acción eliminará todos los mantenimientos asociados a este vehículo y no se podrá deshacer.';

  @override
  String get vehicle_vehicleDeleted => 'Vehículo eliminado exitosamente';

  @override
  String get vehicle_vehicleSetAsMain => 'establecido como vehículo principal';

  @override
  String get vehicle_vehicleArchived => 'archivado';

  @override
  String get vehicle_vehicleUnarchived => 'desarchivado';

  @override
  String get vehicle_noVehicles => 'No tienes vehículos registrados';

  @override
  String get vehicle_noVehiclesAvailable => 'No hay vehículos disponibles';

  @override
  String get vehicle_noArchivedVehicles => 'No hay vehículos archivados';

  @override
  String get vehicle_mainVehicle => 'Vehículo principal';

  @override
  String get vehicle_thisWillBeMainVehicle => 'Este será tu vehículo principal';

  @override
  String get vehicle_archivedVehicle => 'Vehículo Archivado';

  @override
  String get vehicle_archivedVehicleMessage =>
      'Este vehículo está archivado. ¿Deseas continuar editándolo?\nSi actualizas su información, el vehículo será desarchivado y volverá a estar disponible en tu lista de vehículos activos.';

  @override
  String get vehicle_exitSetup => '¿Salir de la configuración?';

  @override
  String get vehicle_exitSetupMessage =>
      'Si sales ahora, perderás el progreso de la configuración del vehículo.';

  @override
  String get vehicle_completeRequiredFields =>
      'Por favor completa todos los campos requeridos';

  @override
  String get vehicle_searchVehicles => 'Buscar por nombre, placa o marca';

  @override
  String get vehicle_vehicleName => 'Nombre del vehículo';

  @override
  String get vehicle_vehicleType => 'Tipo de vehículo';

  @override
  String get vehicle_vehicleBrand => 'Marca';

  @override
  String get vehicle_vehicleModel => 'Modelo';

  @override
  String get vehicle_vehicleYear => 'Año';

  @override
  String get vehicle_vehiclePlate => 'Placa';

  @override
  String get vehicle_vehicleVin => 'VIN';

  @override
  String get vehicle_vehicleNameHint => 'Ej. Mi moto negra';

  @override
  String get vehicle_vehicleBrandHint => 'Ej. Yamaha';

  @override
  String get vehicle_vehicleModelHint => 'Ej. MT-07';

  @override
  String get vehicle_vehicleYearHint => 'Ej. 2022';

  @override
  String get vehicle_vehiclePlateHint => 'Ej. ABC123';

  @override
  String get vehicle_vehicleVinHint => '17 caracteres';

  @override
  String get vehicle_vehiclePhoto => 'Foto del vehículo';

  @override
  String get vehicle_uploadPhoto => 'Subir foto';

  @override
  String get vehicle_selectImage => 'Seleccionar imagen';

  @override
  String get vehicle_changePhoto => 'Cambiar foto';

  @override
  String get vehicle_viewArchived => 'Ver archivados';

  @override
  String get vehicle_showActiveVehicles => 'Mostrar activos';

  @override
  String get vehicle_addFirstVehicle =>
      'Agrega tu primer vehículo para comenzar';

  @override
  String get vehicle_adjustSearch => 'Intenta ajustar la búsqueda';

  @override
  String get vehicle_archiveVehiclesDescription =>
      'Archiva vehículos que ya no uses';

  @override
  String get vehicle_maintenancesTooltip => 'Mantenimientos';

  @override
  String get vehicle_addVehicleTooltip => 'Agregar vehículo';

  @override
  String get vehicle_removeVehicleTooltip => 'Eliminar vehículo';

  @override
  String get vehicle_addAnotherVehicleTooltip => 'Agregar otro vehículo';

  @override
  String get vehicle_welcome => '¡Bienvenido! 🎉';

  @override
  String get vehicle_addAtLeastOneVehicle =>
      'Agrega al menos un vehículo para comenzar';

  @override
  String get vehicle_completeSetup => 'Completar configuración';

  @override
  String get vehicle_nameRequired => 'El nombre es requerido';

  @override
  String get vehicle_vehicleTypeRequired => 'El tipo de vehículo es requerido';

  @override
  String get vehicle_brandRequired => 'La marca es requerida';

  @override
  String get vehicle_brandMustBeFromList =>
      'Selecciona una marca de la lista de sugerencias';

  @override
  String get vehicle_yearRequired => 'El año es requerido';

  @override
  String get vehicle_minCharacters => 'Mínimo 3 caracteres';

  @override
  String get vehicle_invalidYear => 'Año inválido';

  @override
  String get vehicle_purchaseDate => 'Fecha de compra';

  @override
  String get vehicle_purchaseDateHint => 'Ej. 24/12/2025';

  @override
  String get vehicle_car => 'Carro';

  @override
  String get vehicle_motorcycle => 'Moto';

  @override
  String get vehicle_quickInfo => 'Info rápida';

  @override
  String get vehicle_currentMileageLabel => 'Kilometraje actual';

  @override
  String get vehicle_fullSpecs => 'Especificaciones completas';

  @override
  String get vehicle_garageOverview => 'Resumen del garaje';

  @override
  String get vehicle_total => 'TOTAL';

  @override
  String get vehicle_lastRide => 'ÚLTIMO VIAJE';

  @override
  String get vehicle_allVehicles => 'Todos';

  @override
  String get vehicle_maintenanceHistory => 'Historial de Registros';

  @override
  String get vehicle_seeAll => 'Ver todos';

  @override
  String get profile_profile => 'Perfil';

  @override
  String get registration_registrationPageTitle => 'Inscripción al Evento';

  @override
  String get registration_registrationForm => 'Formulario de inscripción';

  @override
  String get registration_myRegistrations => 'Mis inscripciones';

  @override
  String get registration_editRegistration => 'Editar inscripción';

  @override
  String get registration_personalData => 'Datos Personales';

  @override
  String get registration_medicalInfo => 'Información Médica';

  @override
  String get registration_emergencyContactRequired => 'Contacto de emergencia';

  @override
  String get registration_vehicleData => 'Datos del Vehículo';

  @override
  String get registration_personalInfo => 'Información personal';

  @override
  String get registration_emergencyContact => 'Contacto de emergencia';

  @override
  String get registration_vehicleInfo => 'Información del vehículo';

  @override
  String get registration_vehicleRegistered => 'Vehículo registrado';

  @override
  String get registration_firstName => 'Nombres';

  @override
  String get registration_lastName => 'Apellidos';

  @override
  String get registration_identificationNumber => 'Identificación';

  @override
  String get registration_birthDate => 'Fecha Nacimiento';

  @override
  String get registration_phone => 'Celular';

  @override
  String get registration_email => 'Correo Electrónico';

  @override
  String get registration_residenceCity => 'Ciudad Residencia';

  @override
  String get registration_eps => 'EPS';

  @override
  String get registration_medicalInsurance => 'Medicina Prepagada (Opcional)';

  @override
  String get registration_bloodType => 'RH';

  @override
  String get registration_emergencyContactName => 'Nombre completo contacto';

  @override
  String get registration_emergencyContactPhone => 'Celular contacto';

  @override
  String get registration_vehicleBrand => 'Marca';

  @override
  String get registration_vehicleReference => 'Referencia';

  @override
  String get registration_licensePlate => 'Placa';

  @override
  String get registration_vin => 'VIN (Serial)';

  @override
  String get registration_firstNameHint => 'Ej. Juan Carlos';

  @override
  String get registration_lastNameHint => 'Ej. Pérez Rodriguez';

  @override
  String get registration_identificationHint => 'CC/TI/CE';

  @override
  String get registration_birthDateHint => 'mm/dd/yyyy';

  @override
  String get registration_phoneHint => '300 000 0000';

  @override
  String get registration_residenceCityHint => 'Busca tu ciudad';

  @override
  String get registration_emailHint => 'usuario@ejemplo.com';

  @override
  String get registration_epsHint => 'Nombre EPS';

  @override
  String get registration_bloodTypeSelect => 'Seleccione';

  @override
  String get registration_bloodTypeHint => 'RH';

  @override
  String get registration_emergencyContactNameHint => 'Ej. María García';

  @override
  String get registration_emergencyContactPhoneHint => '300 000 0000';

  @override
  String get registration_medicalInsuranceHint =>
      'Entidad de medicina prepagada';

  @override
  String get registration_vehicleBrandHint => 'Ej. Yamaha';

  @override
  String get registration_vehicleReferenceHint => 'Ej. MT-09';

  @override
  String get registration_licensePlateHint => 'ABC-12D';

  @override
  String get registration_vinHint => '17 Caracteres';

  @override
  String get registration_preloadFromVehicle => 'Precargar vehículo';

  @override
  String get registration_selectVehicleToPreload =>
      'Selecciona un vehículo para precargar la información';

  @override
  String get registration_clearForm => 'Limpiar formulario';

  @override
  String get registration_sendRegistration => 'Enviar inscripción';

  @override
  String get registration_updateRegistration => 'Actualizar inscripción';

  @override
  String get registration_registrationSentSuccess =>
      'Inscripción enviada exitosamente. Está pendiente de aprobación.';

  @override
  String get registration_registrationUpdatedSuccess =>
      'Inscripción actualizada exitosamente.';

  @override
  String get registration_registrationCancelledSuccess =>
      'Inscripción cancelada exitosamente.';

  @override
  String get registration_noRegistrations => 'No tienes inscripciones';

  @override
  String get registration_noRegistrationsDescription =>
      'Explora los eventos disponibles y únete a la aventura';

  @override
  String get registration_firstNameRequired => 'Los nombres son requeridos';

  @override
  String get registration_lastNameRequired => 'Los apellidos son requeridos';

  @override
  String get registration_idRequired =>
      'El número de identificación es requerido';

  @override
  String get registration_idInvalidLength =>
      'La cédula debe tener entre 6 y 10 dígitos (estándar Colombia)';

  @override
  String get registration_birthDateRequired =>
      'La fecha de nacimiento es requerida';

  @override
  String get registration_phoneRequired => 'El celular es requerido';

  @override
  String get registration_phoneInvalidLength =>
      'El celular debe tener 10 dígitos (estándar Colombia)';

  @override
  String get registration_emailRequired => 'El correo electrónico es requerido';

  @override
  String get registration_emailInvalid => 'Correo electrónico inválido';

  @override
  String get registration_residenceCityRequired =>
      'La ciudad de residencia es requerida';

  @override
  String get registration_epsRequired => 'La EPS es requerida';

  @override
  String get registration_bloodTypeRequired => 'El tipo de sangre es requerido';

  @override
  String get registration_emergencyContactNameRequired =>
      'El nombre del contacto de emergencia es requerido';

  @override
  String get registration_emergencyContactPhoneRequired =>
      'El celular del contacto de emergencia es requerido';

  @override
  String get registration_emergencyContactPhoneInvalidLength =>
      'El celular del contacto debe tener 10 dígitos (estándar Colombia)';

  @override
  String get registration_vehicleBrandRequired =>
      'La marca del vehículo es requerida';

  @override
  String get registration_vehicleReferenceRequired =>
      'La referencia del vehículo es requerida';

  @override
  String get registration_licensePlateRequired => 'La placa es requerida';

  @override
  String get registration_minCharacters => 'Mínimo 2 caracteres';

  @override
  String get registration_errorLoadingRegistrations =>
      'Error al cargar las inscripciones';

  @override
  String get registration_errorSendingRegistration =>
      'Error al enviar la inscripción';

  @override
  String get registration_viewDetail => 'Ver detalle';

  @override
  String get registration_viewEvent => 'Ver evento';

  @override
  String get registration_goToEvents => 'Ir a eventos';

  @override
  String get registration_details => 'Detalles';

  @override
  String get registration_myRegistration => 'Mi registro';

  @override
  String get registration_reason => 'Motivo';

  @override
  String get registration_reRegister => 'Re-inscribirse';

  @override
  String get registration_registrationDetail => 'Detalle de inscripción';

  @override
  String get registration_registrationDetailTitle => 'Detalle de Registro';

  @override
  String get registration_requestDetailsTitle => 'Detalle de solicitud';

  @override
  String get registration_eventInfo => 'Información del evento';

  @override
  String get registration_inscriptionDate => 'Fecha de inscripción';

  @override
  String get registration_appliedOnPrefix => 'Inscrito el ';

  @override
  String get registration_errorLoadingEvent => 'Error al cargar el evento';

  @override
  String get registration_sectionPersonalInfo => 'Datos personales';

  @override
  String get registration_sectionHealthSafety => 'Salud y seguridad';

  @override
  String get registration_sectionVehicleDetails => 'Datos del vehículo';

  @override
  String get registration_fullNameLabel => 'Nombres Completos';

  @override
  String get registration_identificationIdLabel => 'Identificación (ID)';

  @override
  String get registration_birthDateLabel => 'Fecha de Nacimiento';

  @override
  String get registration_bloodTypeLabel => 'Tipo de Sangre';

  @override
  String get registration_epsOrInsuranceLabel => 'EPS / Seguro';

  @override
  String get registration_brandModelLabel => 'Marca / Modelo';

  @override
  String get registration_cityLabel => 'Ciudad';

  @override
  String get registration_motorcycleLabel => 'Motocicleta';

  @override
  String get registration_plateLabel => 'Placa';

  @override
  String get registration_reject => 'Rechazar';

  @override
  String get registration_approve => 'Aprobar';

  @override
  String get registration_cancelRegistration => 'Cancelar inscripción';

  @override
  String get registration_contactLabel => 'Contactar';

  @override
  String get registration_callLabel => 'Llamar';

  @override
  String get registration_whatsappLabel => 'WhatsApp';

  @override
  String get splash_appName => 'RIDEGLORY';

  @override
  String get splash_appNameRide => 'RIDE';

  @override
  String get splash_appNameGlory => 'GLORY';

  @override
  String get splash_tagline => 'CONNECT. RIDE. EXPLORE.';

  @override
  String get splash_initializingLabel => 'INITIALIZING SYSTEMS';

  @override
  String get splash_versionLabel => 'VERSION 2.4.0';

  @override
  String get splash_retryLabel => 'REINTENTAR';

  @override
  String get splash_errorPrefix => 'Error: ';

  @override
  String get home_greeting => 'Hola, Rider';

  @override
  String get home_myGarage => 'Mi garaje';

  @override
  String get home_viewAll => 'Ver todas';

  @override
  String get home_upcomingRides => 'Próximas rodadas';

  @override
  String get home_viewAllEvents => 'Ver catálogo completo de eventos';

  @override
  String get home_addVehicle => 'Agregar vehículo';

  @override
  String get home_addMaintenance => 'Agregar mantenimiento';

  @override
  String get home_addEvent => 'Agregar evento';

  @override
  String get home_nextOilChange => 'Próximo cambio de aceite en';

  @override
  String get home_viewDetails => 'Ver detalles';

  @override
  String get home_emptyGarage => 'Sin vehículos en tu garaje';

  @override
  String get home_emptyGarageDescription =>
      'Agrega tu primera moto para comenzar';

  @override
  String get home_emptyEvents => 'Sin rodadas próximas';

  @override
  String get home_emptyEventsDescription =>
      'Explora el catálogo de eventos disponibles';

  @override
  String event_pendingCountBadge(Object count) {
    return '$count PENDIENTES';
  }

  @override
  String event_allWithCount(Object count) {
    return 'Todos ($count)';
  }

  @override
  String event_timeAgoHours(Object hours) {
    return 'Hace ${hours}h';
  }

  @override
  String event_timeAgoMinutes(Object minutes) {
    return 'Hace ${minutes}m';
  }

  @override
  String event_timeAgoDays(Object days) {
    return 'Hace ${days}d';
  }

  @override
  String event_approveConfirmMessage(Object name) {
    return '¿Aprobar la inscripción de $name?';
  }

  @override
  String event_rejectConfirmMessage(Object name) {
    return '¿Rechazar la inscripción de $name?';
  }

  @override
  String event_setReadyForEditConfirmMessage(Object name) {
    return '¿Habilitar edición para $name?';
  }

  @override
  String maintenance_performedOn(Object date) {
    return 'Completado el $date';
  }

  @override
  String maintenance_remainingDistance(Object distance, Object unit) {
    return '$distance $unit restantes';
  }

  @override
  String event_difficultyLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'Fácil',
      '2': 'Moderado',
      '3': 'Intermedio',
      '4': 'Difícil',
      '5': 'Muy difícil',
      'other': 'Intermedio',
    });
    return '$_temp0';
  }
}
