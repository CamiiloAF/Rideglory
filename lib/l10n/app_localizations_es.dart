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
  String get noResults => 'No se encontraron resultados';

  @override
  String get noSearchResultsHint => 'Intenta ajustar los filtros o la búsqueda';

  @override
  String get notAvailable => 'N/A';

  @override
  String get loading => 'Cargando...';

  @override
  String get success => 'Éxito';

  @override
  String get savedSuccessfully => 'Guardado exitosamente';

  @override
  String get deletedSuccessfully => 'Eliminado exitosamente';

  @override
  String get updatedSuccessfully => 'Actualizado exitosamente';

  @override
  String get comingSoon => 'próximamente';

  @override
  String get required => 'es requerido';

  @override
  String get mustBeNumber => 'Debe ser un número';

  @override
  String get mustBeGreaterThanZero => 'Debe ser mayor a 0';

  @override
  String get mustBeGreaterThan => 'Debe ser mayor a';

  @override
  String errorMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get auth_emailHint => 'correo@ejemplo.com';

  @override
  String get auth_orContinueWithStitch => 'O continúa con';

  @override
  String get auth_appleLabel => 'Apple';

  @override
  String get auth_nameHint => 'Ej. Juan Pérez';

  @override
  String get auth_nameRequired => 'El nombre completo es requerido';

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
  String get auth_signIn => 'Ingresar';

  @override
  String get auth_signInLink => 'aquí';

  @override
  String get auth_email => 'Correo electrónico';

  @override
  String get auth_password => 'Contraseña';

  @override
  String get auth_enterEmail => 'Ingrese su correo electrónico';

  @override
  String get auth_enterPassword => 'Ingresa tu contraseña';

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
  String get event_editEvent => 'Editar evento';

  @override
  String get event_eventDetail => 'Detalle del Evento';

  @override
  String get event_deleteEvent => 'Eliminar Evento';

  @override
  String get event_optionsTitle => 'Opciones del evento';

  @override
  String get event_edit => 'Editar';

  @override
  String get event_delete => 'Eliminar';

  @override
  String get event_startEvent => 'Iniciar evento';

  @override
  String get event_stopEvent => 'Detener evento';

  @override
  String get event_stopEventConfirmTitle => '¿Finalizar rodada?';

  @override
  String get event_stopEventConfirmMessage =>
      'Se cerrará el seguimiento en vivo para todos los participantes.';

  @override
  String get event_requestUnderReview =>
      'Tu solicitud está siendo revisada por el organizador.';

  @override
  String get event_registrationRejected => 'Inscripción rechazada';

  @override
  String get event_rejectedMessage =>
      'El organizador no aprobó tu solicitud para este evento.';

  @override
  String get event_eventCancelled => 'Evento cancelado';

  @override
  String get event_cancelledMessage =>
      'Este evento fue cancelado por el organizador.';

  @override
  String get event_participantsReady => 'Participantes listos para iniciar';

  @override
  String get event_rideInProgress => 'Rodada en progreso';

  @override
  String get event_saveDraft => 'Guardar borrador';

  @override
  String get event_meetingTimePrefix => 'Encuentro: ';

  @override
  String get event_allBrands => 'Todas las marcas';

  @override
  String get event_eventName => 'Nombre del evento';

  @override
  String get event_eventCity => 'Ciudad';

  @override
  String get event_eventCityHint => 'Buscar ciudad y departamento...';

  @override
  String get event_filterDateHint => 'Seleccionar';

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
  String get event_eventType => 'Tipo de evento';

  @override
  String get event_finalDestination => 'Destino final';

  @override
  String get event_searchBrandsPlaceholder => 'Escribe para buscar marcas...';

  @override
  String get event_allowedBrands => 'Marcas permitidas';

  @override
  String get event_allowedBrandsHint => 'Honda, Yamaha, Kawasaki...';

  @override
  String get event_allowedBrandsHelper =>
      'Separar con coma. Dejar vacío si acepta todas las marcas.';

  @override
  String get event_price => 'Precio del evento (opcional)';

  @override
  String get event_startDateMustBeBeforeEndDate =>
      'La fecha de inicio debe ser anterior a la fecha de fin';

  @override
  String get event_updateEvent => 'Actualizar Evento';

  @override
  String get event_publishEvent => 'Publicar evento';

  @override
  String get event_newEvent => 'Nuevo evento';

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
  String get event_coverGenerateError =>
      'No pudimos generar la portada. Sube tu propia imagen.';

  @override
  String get event_coverRegenerate => 'Regenerar';

  @override
  String get event_coverGeneratingOverlay => 'Generando con IA...';

  @override
  String get event_route => 'RUTA';

  @override
  String get event_multiBrandLabel => 'Marcas permitidas';

  @override
  String get event_multiBrandAllowAny =>
      'Permitir motos de cualquier fabricante';

  @override
  String get event_selectBrands => 'Seleccionar marcas permitidas';

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
  String get event_viewAttendees => 'Ver inscritos';

  @override
  String get event_meetingPointLabel => 'Punto de encuentro';

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
  String get event_alreadyRegistered => 'Ya estás inscrito en este evento';

  @override
  String get event_eventFinished => 'Finalizado';

  @override
  String get event_free => 'Gratuito';

  @override
  String get event_eventCardPriceFree => 'Gratis';

  @override
  String get event_eventCardMyEvent => 'Mi evento';

  @override
  String get event_pending => 'Pendiente';

  @override
  String get event_approved => 'Aprobado';

  @override
  String get event_rejected => 'Rechazado';

  @override
  String get event_cancelledDescription => 'Cancelaste tu inscripción.';

  @override
  String get event_participants => 'Participantes';

  @override
  String get event_attendeesCount => 'personas inscritas';

  @override
  String get event_approveRegistration => 'Aprobar';

  @override
  String get event_rejectRegistration => 'Rechazar';

  @override
  String get event_noAttendees => 'No hay inscritos aún';

  @override
  String get event_newRequestsSection => 'NUEVAS SOLICITUDES';

  @override
  String get event_pendingBadgeSuffix => 'PENDIENTES';

  @override
  String get event_processedSection => 'YA PROCESADOS';

  @override
  String get event_approvedBadge => 'APROBADO';

  @override
  String get event_rejectedBadge => 'RECHAZADO';

  @override
  String get event_searchAttendees => 'Buscar participantes';

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
  String get event_meetingPointRequired => 'El punto de encuentro es requerido';

  @override
  String get event_destinationRequired => 'El destino es requerido';

  @override
  String get event_difficultyRequired => 'La dificultad es requerida';

  @override
  String event_form_difficulty_description(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'Fácil — ideal para principiantes y rodadas familiares',
      '2': 'Moderado — experiencia básica en ruta recomendada',
      '3': 'Intermedio — requiere experiencia en rutas largas',
      '4': 'Difícil — habilidades avanzadas necesarias',
      '5': 'Extrema — solo para riders expertos',
      'other': 'Selecciona el nivel de dificultad',
    });
    return '$_temp0';
  }

  @override
  String get event_form_difficulty_section_title => 'DIFICULTAD';

  @override
  String get event_form_difficulty_level_label => 'Nivel de dificultad';

  @override
  String get event_eventTypeRequired => 'El tipo de evento es requerido';

  @override
  String get event_minCharacters => 'Mínimo 3 caracteres';

  @override
  String get event_invalidPrice => 'Precio inválido';

  @override
  String get map_riderTelemetry => 'Rider telemetry';

  @override
  String get map_speed => 'Velocidad';

  @override
  String get map_distanceFromYou => 'Desde ti';

  @override
  String get map_battery => 'Batería';

  @override
  String get map_sos => 'SOS';

  @override
  String get map_riderLead => 'Lead';

  @override
  String get map_riderRole => 'Rider';

  @override
  String get map_endRideConfirmTitle => '¿Finalizar rodada?';

  @override
  String get map_endRideConfirmMessage =>
      'Se cerrará el seguimiento en vivo para todos los participantes. Esta acción no se puede deshacer.';

  @override
  String get map_endRideConfirmButton => 'Sí, finalizar';

  @override
  String get map_sosAlertTitle => 'Alerta SOS activa';

  @override
  String get map_sosAlertMessage =>
      'Has enviado una alerta de emergencia. Los demás participantes verán tu ubicación y sabrán que necesitas ayuda.';

  @override
  String get map_sosDismiss => 'Cancelar alerta';

  @override
  String get map_sosConfirmTitle => '¿Enviar SOS?';

  @override
  String get map_sosConfirmMessage =>
      'Esto notificará a todos los participantes de la rodada sobre tu emergencia y compartirá tu ubicación en tiempo real.';

  @override
  String get map_sosSend => 'Enviar SOS';

  @override
  String get map_participantsTitle => 'Participantes';

  @override
  String get map_activeRiders => 'en rodada';

  @override
  String get map_noActiveRidersMessage =>
      'No hay riders activos en este momento';

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
  String get maintenance_deleteMaintenanceMessage =>
      '¿Estás seguro de que deseas eliminar este mantenimiento?\nEsta acción no se puede deshacer.';

  @override
  String get maintenance_noMaintenances => 'No hay mantenimientos registrados';

  @override
  String get maintenance_noMaintenancesDescription =>
      'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo';

  @override
  String get maintenance_maintenanceDeletedSuccessfully =>
      'Mantenimiento eliminado correctamente';

  @override
  String get maintenance_maintenanceNotes => 'Notas / Observaciones';

  @override
  String get maintenance_nextMaintenanceMileage =>
      'Kilometraje del próximo mantenimiento';

  @override
  String get maintenance_totalCost => 'Costo total';

  @override
  String get maintenance_serviceNotes => 'Notas de servicio';

  @override
  String get maintenance_routine => 'Rutina';

  @override
  String get maintenance_filters => 'Filtros';

  @override
  String get maintenance_myVehicles => 'Mis Vehículos';

  @override
  String get maintenance_currentMileage => 'Kilometraje Actual';

  @override
  String get maintenance_updateMileage => 'Actualizar kilometraje';

  @override
  String get maintenance_km => 'km';

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
  String get maintenance_viewHistory => 'Ver historial de mantenimientos';

  @override
  String get maintenance_saveMaintenance => 'Guardar Registro';

  @override
  String get maintenance_saveOnly => 'Solo guardar';

  @override
  String get maintenance_update => 'Actualizar';

  @override
  String get maintenance_sortByNextMaintenance => 'Próximo mantenimiento';

  @override
  String get maintenance_sortByDate => 'Fecha de realización';

  @override
  String get maintenance_sortByName => 'Nombre';

  @override
  String get maintenance_vehicle => 'Vehículo';

  @override
  String get maintenance_next => 'Próximo';

  @override
  String get maintenance_done => 'Hecho';

  @override
  String get maintenance_calculateRemainingDistance =>
      'Calcular distancia restante';

  @override
  String get maintenance_maintenanceDateLabel => 'Fecha de Servicio';

  @override
  String get maintenance_sectionDetails => 'DETALLES DEL SERVICIO';

  @override
  String get maintenance_searchMaintenances =>
      'Buscar por nombre del mantenimiento';

  @override
  String get maintenance_allVehicles => 'Todos los vehículos';

  @override
  String get vehicle_addShort => 'Agregar';

  @override
  String get vehicle_specBrand => 'Marca';

  @override
  String get vehicle_specModel => 'Modelo';

  @override
  String get vehicle_specYear => 'Año';

  @override
  String get vehicle_specPurchaseDate => 'Fecha de compra';

  @override
  String get vehicle_identification => 'Identificación del vehículo';

  @override
  String get vehicle_specs => 'Especificaciones';

  @override
  String get vehicle_plate => 'Placa';

  @override
  String get vehicle_vinLabel => 'VIN / No. de Serie';

  @override
  String get vehicle_myGarage => 'Mi Garaje';

  @override
  String get vehicle_addVehicle => 'Agregar vehículo';

  @override
  String get vehicle_editVehicle => 'Editar vehículo';

  @override
  String get vehicle_deleteVehicle => 'Eliminar vehículo';

  @override
  String get vehicle_addMaintenance => 'Agregar mantenimiento';

  @override
  String get vehicle_selectVehicle => 'Seleccionar vehículo';

  @override
  String get vehicle_archiveVehicle => 'Archivar';

  @override
  String get vehicle_unarchiveVehicle => 'Desarchivar';

  @override
  String vehicle_deleteVehicleConfirmContent(String vehicleName) {
    return '¿Estás seguro de que deseas eliminar «$vehicleName»?\n\nEsta acción eliminará todos los mantenimientos asociados a este vehículo y no se podrá deshacer.';
  }

  @override
  String get vehicle_vehicleDeleted => 'Vehículo eliminado exitosamente';

  @override
  String get vehicle_noVehicles => 'No tienes vehículos registrados';

  @override
  String get vehicle_mainVehicle => 'Vehículo principal';

  @override
  String get vehicle_archivedVehicle => 'Vehículo Archivado';

  @override
  String get vehicle_archivedVehicleMessage =>
      'Este vehículo está archivado. ¿Deseas continuar editándolo?\nSi actualizas su información, el vehículo será desarchivado y volverá a estar disponible en tu lista de vehículos activos.';

  @override
  String get vehicle_vehicleName => 'Nombre del vehículo';

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
  String get vehicle_nameRequired => 'El nombre es requerido';

  @override
  String get vehicle_brandRequired => 'La marca es requerida';

  @override
  String get vehicle_modelRequired => 'El modelo es requerido';

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
  String get profile_title => 'Mi perfil';

  @override
  String get profile_mainVehicle => 'Vehículo principal';

  @override
  String get profile_noVehicle => 'Sin vehículos';

  @override
  String get profile_loadingError => 'No pudimos cargar tu perfil';

  @override
  String get profile_editTitle => 'Editar perfil';

  @override
  String get profile_editSave => 'Guardar cambios';

  @override
  String get profile_fieldFullName => 'Nombre completo';

  @override
  String get profile_fieldPhone => 'Teléfono';

  @override
  String get profile_fieldCity => 'Ciudad de residencia';

  @override
  String get profile_fieldBloodType => 'Tipo de sangre';

  @override
  String get profile_fieldEmergencyContact => 'Contacto de emergencia';

  @override
  String get profile_fieldEmergencyPhone => 'Teléfono de emergencia';

  @override
  String get profile_sectionPersonal => 'Información personal';

  @override
  String get profile_sectionEmergency => 'Contacto de emergencia';

  @override
  String get profile_editInfo => 'Editar perfil';

  @override
  String get profile_statsEvents => 'Rodadas';

  @override
  String get profile_statsKm => 'Km';

  @override
  String get profile_statsFollowers => 'Seguidores';

  @override
  String get profile_settings => 'Configuración';

  @override
  String get profile_registrations => 'Mis inscripciones';

  @override
  String get profile_maintenances => 'Mantenimientos';

  @override
  String get profile_analyticsOptOutLabel => 'Compartir datos de uso anónimos';

  @override
  String get profile_analyticsOptOutSaveError =>
      'No pudimos guardar tu preferencia. Inténtalo de nuevo.';

  @override
  String get registration_registrationPageTitle => 'Inscripción al Evento';

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
  String get registration_emergencyContact => 'Contacto de emergencia';

  @override
  String get registration_fullName => 'Nombre completo';

  @override
  String get registration_fullNameHint => 'Ej. Juan Carlos Pérez Rodríguez';

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
  String get registration_fullNameRequired => 'El nombre completo es requerido';

  @override
  String get registration_identificationHint => 'Documento de identidad';

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
  String get registration_bloodTypeHint => 'RH';

  @override
  String get registration_emergencyContactNameHint => 'Ej. María García';

  @override
  String get registration_emergencyContactPhoneHint => '300 000 0000';

  @override
  String get registration_medicalInsuranceHint =>
      'Entidad de medicina prepagada';

  @override
  String get registration_selectVehicleToPreload => 'Selecciona un vehículo';

  @override
  String get registration_selectVehiclePlaceholder => 'Selecciona tu vehículo';

  @override
  String get registration_changeVehicle => 'Cambiar';

  @override
  String get registration_vehicleEmptyStateSubtitle =>
      'Registra tu moto para inscribirte en el evento.';

  @override
  String get registration_vehicleBrandNotAllowed =>
      'La marca seleccionada no está permitida para este evento. Las marcas pemitidas son';

  @override
  String get registration_vehicleEmptyStateTitle =>
      'No tienes vehículos disponibles para esta inscripción.';

  @override
  String get registration_createVehicleCta => 'Crear vehículo';

  @override
  String get registration_sendRegistration => 'Enviar inscripción';

  @override
  String get registration_updateRegistration => 'Actualizar inscripción';

  @override
  String get registration_finishRegistration => 'Confirmar Inscripción';

  @override
  String get registration_nextStep => 'Siguiente';

  @override
  String get registration_previousStep => 'Atrás';

  @override
  String get registration_stepPersonalTitle => 'Información Personal';

  @override
  String get registration_stepPersonalSubtitle => 'Datos básicos del piloto';

  @override
  String get registration_stepMedicalTitle => 'Información Médica';

  @override
  String get registration_stepMedicalSubtitle =>
      'Datos de salud para el evento';

  @override
  String get registration_stepEmergencyTitle => 'Contacto de Emergencia';

  @override
  String get registration_stepEmergencySubtitle =>
      'Persona a contactar en caso de accidente';

  @override
  String get registration_stepVehicleTitle => 'Vehículo de Inscripción';

  @override
  String get registration_stepVehicleSubtitle =>
      'Moto con la que participarás en el evento';

  @override
  String get registration_bloodTypeSelectHint => 'Selecciona tu grupo';

  @override
  String get registration_saveToProfile =>
      'Guardar mis datos para futuras inscripciones';

  @override
  String get registration_registrationSentSuccess =>
      'Inscripción enviada exitosamente. Está pendiente de aprobación.';

  @override
  String get registration_registrationUpdatedSuccess =>
      'Inscripción actualizada exitosamente.';

  @override
  String get registration_noRegistrations => 'No tienes inscripciones';

  @override
  String get registration_noRegistrationsDescription =>
      'Explora los eventos disponibles y únete a la aventura';

  @override
  String get registration_idRequired =>
      'El número de identificación es requerido';

  @override
  String get registration_idInvalidLength =>
      'La cédula debe tener entre 6 y 10 dígitos (estándar Colombia)';

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
  String get registration_minCharacters => 'Mínimo 2 caracteres';

  @override
  String get registration_errorLoadingRegistrations =>
      'Error al cargar las inscripciones';

  @override
  String get registration_viewDetail => 'Ver detalle';

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
  String get registration_requestDetailsTitle => 'Detalle de solicitud';

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
  String get registration_bloodTypeLabel => 'Tipo de Sangre';

  @override
  String get registration_epsOrInsuranceLabel => 'EPS / Seguro';

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
  String get registration_emergencyContactTitle => 'Contacto de Emergencia';

  @override
  String get registration_participationData => 'Datos de Participación';

  @override
  String get registration_rowName => 'Nombre';

  @override
  String get registration_rowIdentification => 'Identificación';

  @override
  String get registration_rowBirthDate => 'Fecha de nacimiento';

  @override
  String get registration_rowPhone => 'Teléfono';

  @override
  String get registration_rowEmail => 'Correo electrónico';

  @override
  String get registration_rowCity => 'Ciudad';

  @override
  String get registration_rowEps => 'EPS';

  @override
  String get registration_rowMedicalInsurance => 'Seguro médico';

  @override
  String get registration_rowBloodType => 'Tipo de sangre';

  @override
  String get registration_rowContactName => 'Nombre del contacto';

  @override
  String get registration_rowVehicle => 'Vehículo';

  @override
  String get registration_rowParticipationType => 'Tipo de participación';

  @override
  String get registration_rowCompanions => 'Acompañantes';

  @override
  String get registration_participationRiderPrincipal => 'Rider principal';

  @override
  String get registration_requestEdit => 'Solicitar edición';

  @override
  String get registration_editRegistrationCta => 'Editar inscripción';

  @override
  String get registration_pendingBannerText =>
      'Tu inscripción está pendiente de revisión';

  @override
  String get registration_rejectedBannerText => 'Tu inscripción fue rechazada';

  @override
  String get registration_readyForEditBannerText =>
      'Puedes editar tu inscripción';

  @override
  String get registration_approvedBannerText => 'Tu inscripción fue aprobada';

  @override
  String get registration_cancelledBannerText => 'Cancelaste tu inscripción';

  @override
  String get splash_retryLabel => 'REINTENTAR';

  @override
  String get splash_errorPrefix => 'Error: ';

  @override
  String get home_greeting => 'Hola, Rider';

  @override
  String get home_viewDetails => 'Ver detalles';

  @override
  String get appfields_mileageRequired => 'El kilometraje es requerido';

  @override
  String event_approveConfirmMessage(Object name) {
    return '¿Aprobar la inscripción de $name?';
  }

  @override
  String event_rejectConfirmMessage(Object name) {
    return '¿Rechazar la inscripción de $name?';
  }

  @override
  String get registration_requestEditConfirmTitle => 'Solicitar edición';

  @override
  String registration_requestEditConfirmMessage(Object name) {
    return '¿Pedirle a $name que edite su inscripción?';
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
  String get event_noResultsFiltered => 'No hay eventos con estos filtros';

  @override
  String get rider_profileTitle => 'Perfil del motorista';

  @override
  String get rider_follow => 'Seguir';

  @override
  String get rider_statsEvents => 'Rodadas';

  @override
  String get rider_statsFollowers => 'Seguidores';

  @override
  String get rider_statsFollowing => 'Siguiendo';

  @override
  String get auth_welcome_title => 'Bienvenido';

  @override
  String get auth_welcome_subtitle => 'Inicia sesión para continuar';

  @override
  String get auth_email_label => 'Correo electrónico';

  @override
  String get auth_email_placeholder => 'tu@correo.com';

  @override
  String get auth_password_label => 'Contraseña';

  @override
  String get auth_password_placeholder => 'Mínimo 8 caracteres';

  @override
  String get auth_forgot_password => '¿Olvidaste tu contraseña?';

  @override
  String get auth_sign_in => 'Iniciar sesión';

  @override
  String get auth_continue_with_google => 'Continuar con Google';

  @override
  String get auth_no_account => '¿No tienes cuenta?';

  @override
  String get auth_register_link => 'Regístrate';

  @override
  String get auth_create_account_title => 'Crear cuenta';

  @override
  String get auth_join_community => 'Únete a la comunidad';

  @override
  String get auth_full_name_label => 'Nombre completo';

  @override
  String get auth_confirm_password_label => 'Confirmar contraseña';

  @override
  String get auth_terms_text =>
      'Acepto los Términos de uso y la Política de privacidad de Rideglory';

  @override
  String get auth_create_account_btn => 'Crear cuenta';

  @override
  String get auth_already_have_account => '¿Ya tienes cuenta?';

  @override
  String get auth_sign_in_link => 'Inicia sesión';

  @override
  String get auth_recovery_heading => '¿Olvidaste tu contraseña?';

  @override
  String get auth_recovery_subtitle =>
      'Ingresa tu correo y te enviaremos un enlace para restablecerla.';

  @override
  String get auth_recovery_send => 'Enviar enlace';

  @override
  String get auth_recovery_back => '← Volver al inicio de sesión';

  @override
  String get auth_recovery_sent_title => 'Correo enviado';

  @override
  String auth_recovery_sent_body(String email) {
    return 'Revisamos tu correo en $email. El enlace expira en 15 minutos.';
  }

  @override
  String get auth_recovery_back_home => 'Volver al inicio';

  @override
  String get auth_recovery_resend => 'No recibí el correo — reenviar';

  @override
  String get home_sectionGarage => 'Mi garaje';

  @override
  String get home_sectionEvents => 'Próximas rodadas';

  @override
  String get home_viewAllLink => 'Ver todas';

  @override
  String get home_viewCatalog => 'Ver catálogo completo de eventos';

  @override
  String get home_emptyGarageTitle => 'Agrega tu primera moto';

  @override
  String get home_emptyGarageSubtitle =>
      'Lleva el control de tu garaje y mantenimientos';

  @override
  String get home_emptyGarageCta => 'Agregar moto';

  @override
  String get home_emptyEventsTitle => 'Sin rodadas próximas';

  @override
  String get home_emptyEventsSubtitle =>
      'Explora los eventos disponibles y únete a la comunidad';

  @override
  String get home_emptyEventsCta => 'Ver eventos';

  @override
  String get event_form_max_participants_label => 'Cupos disponibles';

  @override
  String get event_form_publish_action => 'Publicar';

  @override
  String get event_form_optional_badge => 'Opcional';

  @override
  String get event_form_max_participants_section_title =>
      'MÁXIMO DE PARTICIPANTES';

  @override
  String get event_form_max_participants_subtitle =>
      'Deja vacío para no limitar inscritos';

  @override
  String get event_form_max_participants_hint =>
      'Una vez lleno el cupo, el evento aparece como \'Completo\' automáticamente.';

  @override
  String get event_form_price_section_title => 'PRECIO DE INSCRIPCIÓN';

  @override
  String get event_form_price_free_hint =>
      'Si el precio es 0, el evento será gratuito';

  @override
  String get vehicle_doc_soat_label => 'SOAT';

  @override
  String get vehicle_doc_techreview_label => 'Técnico-mecánica';

  @override
  String get vehicle_form_brand_label => 'Marca';

  @override
  String get vehicle_form_model_label => 'Modelo';

  @override
  String get vehicle_form_year_label => 'Año';

  @override
  String get vehicle_form_color_label => 'Color';

  @override
  String get vehicle_form_plate_label => 'Placa';

  @override
  String get vehicle_form_km_label => 'Kilometraje actual';

  @override
  String get vehicle_form_cover_title => 'Agregar foto de portada';

  @override
  String get vehicle_form_cover_subtitle => 'JPG, PNG · Máx. 10MB';

  @override
  String get vehicle_form_upload_btn => 'Subir';

  @override
  String get vehicle_form_take_photo_btn => 'Tomar foto';

  @override
  String get vehicle_form_scan_title => 'Escanear tarjeta de propiedad';

  @override
  String get vehicle_form_scan_subtitle =>
      'Autocompleta marca, modelo, año, placa y VIN automáticamente';

  @override
  String get vehicle_form_info_section => 'INFORMACIÓN BÁSICA';

  @override
  String get vehicle_form_id_section => 'IDENTIFICACIÓN';

  @override
  String get vehicle_form_color_hint => 'Ej. Azul, Negro mate';

  @override
  String get vehicle_form_docs_section => 'DOCUMENTOS';

  @override
  String get vehicle_form_soat_subtitle => 'Seguro obligatorio de accidentes';

  @override
  String get vehicle_form_techreview_subtitle => 'Rev. técnica del vehículo';

  @override
  String get vehicle_form_add_doc_title => 'Agregar otro documento';

  @override
  String get vehicle_form_add_doc_subtitle => 'PDF, JPG, PNG · Máx. 5 MB';

  @override
  String get vehicle_form_docs_max_hint => 'Máximo 3 documentos por vehículo';

  @override
  String get vehicle_form_save => 'Guardar moto';

  @override
  String get vehicle_form_delete_vehicle => 'Eliminar vehículo';

  @override
  String get vehicle_form_placa_required_badge => 'Obligatorio';

  @override
  String get vehicle_form_vin_optional_label => 'Opcional';

  @override
  String get vehicle_form_specs_section => 'ESPECIFICACIONES';

  @override
  String get vehicle_form_specs_engine_label => 'Motor';

  @override
  String get vehicle_form_specs_horsepower_label => 'Potencia';

  @override
  String get vehicle_form_specs_torque_label => 'Torque';

  @override
  String get vehicle_form_specs_weight_label => 'Peso';

  @override
  String get vehicle_form_specs_engine_hint => 'Ej. 689cc · Paralelo 2 cil.';

  @override
  String get vehicle_form_specs_horsepower_hint => 'Ej. 73 hp';

  @override
  String get vehicle_form_specs_torque_hint => 'Ej. 68 Nm';

  @override
  String get vehicle_form_specs_weight_hint => 'Ej. 179 kg';

  @override
  String get maintenance_form_new_title => 'Nuevo Mantenimiento';

  @override
  String get maintenance_form_step_select_label => 'Paso 1 de 2';

  @override
  String get maintenance_form_step_select =>
      'Selecciona el tipo de mantenimiento';

  @override
  String get maintenance_form_step_continue => 'Continuar';

  @override
  String get maintenance_form_tab_done => 'Completado';

  @override
  String get maintenance_form_tab_scheduled => 'Programado';

  @override
  String get maintenance_form_save_done => 'Guardar mantenimiento';

  @override
  String get maintenance_form_discard => 'Descartar';

  @override
  String get maintenance_form_estado_section => 'ESTADO';

  @override
  String get maintenance_form_context_subtitle =>
      'Tipo de mantenimiento seleccionado';

  @override
  String get maintenance_form_km_label => 'Kilometraje al momento del servicio';

  @override
  String get maintenance_form_cost_taller_section => 'COSTO Y TALLER';

  @override
  String get maintenance_form_taller_label => 'Taller / Mecánico';

  @override
  String get maintenance_form_notes_section => 'NOTAS';

  @override
  String get maintenance_form_date_scheduled_label => 'Fecha programada';

  @override
  String get maintenance_scheduled_requires_date_or_km =>
      'Debes ingresar al menos la fecha o los km del próximo mantenimiento';

  @override
  String get maintenance_prox_service_in => 'Próximo servicio en';

  @override
  String get maintenance_filter_type_label => 'Tipo de mantenimiento';

  @override
  String get maintenance_filter_status_label => 'Estado';

  @override
  String get maintenance_filter_status_all => 'Todos';

  @override
  String get maintenance_filter_status_overdue => 'Atrasado';

  @override
  String get maintenance_filter_status_upcoming => 'Próximo';

  @override
  String get maintenance_filter_status_on_track => 'Al día';

  @override
  String get maintenance_filter_date_range_label => 'Rango de fecha';

  @override
  String get maintenance_filter_date_this_month => 'Este mes';

  @override
  String get maintenance_filter_date_last_3_months => 'Últimos 3 meses';

  @override
  String get maintenance_filter_date_last_year => 'Último año';

  @override
  String get maintenance_filter_date_custom => 'Personalizado';

  @override
  String get maintenance_filter_clear => 'Limpiar';

  @override
  String get maintenance_filter_clear_all => 'Limpiar todo';

  @override
  String get filter_title => 'Filtros';

  @override
  String get filter_clearAll => 'Limpiar todo';

  @override
  String get filter_clear => 'Limpiar';

  @override
  String get filter_apply => 'Aplicar';

  @override
  String get maintenance_legend_warning => 'Próximo';

  @override
  String get maintenance_status_overdue => 'atrasado';

  @override
  String get maintenance_km_remaining => 'faltan';

  @override
  String get nav_inicio => 'Inicio';

  @override
  String get nav_garaje => 'Garaje';

  @override
  String get nav_eventos => 'Eventos';

  @override
  String get nav_perfil => 'Perfil';

  @override
  String get notification_centerTitle => 'Notificaciones';

  @override
  String get notification_markAllRead => 'Marcar todo como leído';

  @override
  String get notification_emptyTitle => 'Sin notificaciones';

  @override
  String get notification_emptySubtitle =>
      'Aquí aparecerán tus inscripciones aprobadas, recordatorios de eventos y más.';

  @override
  String get notification_sectionUnread => 'NO LEÍDAS';

  @override
  String get notification_sectionRead => 'ANTERIORES';

  @override
  String get registration_statusBadgeApproved => 'Aprobada';

  @override
  String get registration_statusBadgePending => 'Pendiente';

  @override
  String get registration_statusBadgeRejected => 'Rechazada';

  @override
  String get registration_statusBadgeCancelled => 'Cancelada';

  @override
  String get registration_statusBadgeReadyForEdit => 'Para editar';

  @override
  String get event_registrationsTab => 'Inscritos';

  @override
  String get event_manageAttendeesTitle => 'Gestionar inscritos';

  @override
  String event_attendee_joinedDaysAgo(int days) {
    return 'Se unió hace $days días';
  }

  @override
  String event_attendee_joinedHoursAgo(int hours) {
    return 'Se unió hace $hours h';
  }

  @override
  String event_attendee_joinedMinutesAgo(int minutes) {
    return 'Se unió hace $minutes min';
  }

  @override
  String get event_attendee_joinedRecently => 'Se unió hace un momento';

  @override
  String get sos_banner_subtitle_with_phone => 'Toca para ver acciones';

  @override
  String get sos_banner_subtitle_no_phone => 'Sin teléfono registrado';

  @override
  String get sos_call_action => 'Llamar';

  @override
  String get sos_locate_action => 'Localizar';

  @override
  String sos_locate_sheet_title(String riderName) {
    return 'Localizar a $riderName';
  }

  @override
  String get sos_locate_center_option => 'Centrar en el mapa';

  @override
  String get sos_locate_external_option => 'Abrir en Google Maps';

  @override
  String get sos_cancel_confirm_title => '¿Desactivar SOS?';

  @override
  String get sos_cancel_confirm_body =>
      'Se cancelará tu alerta de emergencia y los demás riders dejarán de verla.';

  @override
  String get sos_cancel_confirm_action => 'Desactivar SOS';

  @override
  String sos_banner_title(String riderName) {
    return '$riderName necesita ayuda';
  }

  @override
  String get tracking_end_ride => 'Terminar rodada';

  @override
  String get tracking_end_ride_confirm_title => '¿Terminar rodada?';

  @override
  String get tracking_end_ride_confirm_body =>
      'La pantalla de rastreo se cerrará para todos los riders conectados. Esta acción no se puede deshacer.';

  @override
  String get tracking_ride_finished => '¡La rodada ha terminado!';

  @override
  String tracking_ride_finished_body(String eventName) {
    return '$eventName ha finalizado exitosamente.';
  }

  @override
  String get tracking_back_to_home => 'Volver al inicio';

  @override
  String get tracking_organizer_badge => 'Organizador';

  @override
  String get tracking_organizer_label => 'Control de rodada';

  @override
  String get vehicle_soat_tap_to_add => 'Sin registrar · Agregar →';

  @override
  String get vehicle_soat_form_title => 'Registrar SOAT';

  @override
  String get vehicle_soat_policy_number_label => 'Número de póliza';

  @override
  String get vehicle_soat_policy_number_hint => 'Ej: SOA-123456';

  @override
  String get vehicle_soat_insurer_label => 'Aseguradora';

  @override
  String get vehicle_soat_insurer_hint => 'Ej: Sura, Colseguros...';

  @override
  String get vehicle_soat_start_date_label => 'Fecha de inicio';

  @override
  String get vehicle_soat_start_date_hint => 'dd/mm/aaaa';

  @override
  String get vehicle_soat_expiry_date_label => 'Fecha de vencimiento';

  @override
  String get vehicle_soat_expiry_date_hint => 'dd/mm/aaaa';

  @override
  String get vehicle_soat_save_button => 'Guardar SOAT';

  @override
  String get vehicle_soat_saved_successfully => 'SOAT registrado exitosamente';

  @override
  String get vehicle_soat_data_added => 'Datos del SOAT agregados';

  @override
  String get vehicle_soat_section_title => 'Documentos';

  @override
  String get vehicle_soat_confirm_title => 'Confirmar SOAT';

  @override
  String get vehicle_soat_confirm_button => 'Confirmar SOAT';

  @override
  String get vehicle_soat_confirm_verify => 'Verifica los datos del SOAT';

  @override
  String get vehicle_soat_confirm_verify_sub =>
      'Revisa y corrige la información antes de confirmar';

  @override
  String get vehicle_soat_manual_section_title => 'Ingresa los datos del SOAT';

  @override
  String get vehicle_soat_manual_section_sub =>
      'Completa la información de tu seguro';

  @override
  String get vehicle_soat_doc_uploaded => 'Documento subido exitosamente';

  @override
  String get vehicle_soat_status_valid => 'SOAT vigente';

  @override
  String vehicle_soat_status_valid_desc(int days) {
    return 'Tu SOAT estará vigente por $days días más';
  }

  @override
  String get vehicle_soat_status_expires_today => 'Vence hoy';

  @override
  String get vehicle_soat_status_expired_title => 'SOAT vencido';

  @override
  String vehicle_soat_status_expired_desc(int days) {
    return 'Venció hace $days días';
  }

  @override
  String get vehicle_soat_status_invalid_dates_title => 'Fechas inválidas';

  @override
  String get vehicle_soat_status_invalid_dates_desc =>
      'La fecha de inicio debe ser anterior al vencimiento';

  @override
  String get vehicle_soat_status_pending => 'Estado del SOAT';

  @override
  String get tracking_sosCallError => 'No se pudo iniciar la llamada.';

  @override
  String get tracking_sosLocationError =>
      'No se pudo obtener la ubicación del rider.';

  @override
  String get tracking_sosMapError => 'No se pudo abrir el mapa.';

  @override
  String get tracking_sosSemanticsLabel => 'Enviar alerta de emergencia';

  @override
  String get map_filterAll => 'Todos';

  @override
  String get map_filterActive => 'Activos';

  @override
  String get map_filterStopped => 'Detenidos';

  @override
  String get map_filterSos => 'SOS';

  @override
  String get map_searchParticipants => 'Buscar por nombre...';

  @override
  String get map_viewProfile => 'Ver perfil';

  @override
  String get map_emergencyCall => 'Llamada de emergencia';

  @override
  String get map_locate => 'Localizar';

  @override
  String get map_stopped => 'Detenido';

  @override
  String get map_geocodeError => 'No se pudo obtener las coordenadas.';

  @override
  String get map_loadError => 'No se pudo cargar el mapa.';

  @override
  String get maintenance_summary_title => 'Resumen de Mantenimientos';

  @override
  String get maintenance_services_count => 'Servicios';

  @override
  String get maintenance_total_spent => 'Total gastado';

  @override
  String get maintenance_overdue_section => 'ATRASADO';

  @override
  String get maintenance_upcoming_section => 'PRÓXIMAMENTE';

  @override
  String get maintenance_on_track_section => 'AL DÍA';

  @override
  String get maintenance_status_done_badge => 'Realizado';

  @override
  String get maintenance_status_scheduled_badge => 'Programado';

  @override
  String get maintenance_service_info => 'Información del servicio';

  @override
  String get maintenance_service_date => 'Fecha del servicio';

  @override
  String get maintenance_odometer_km => 'Odómetro';

  @override
  String get maintenance_next_review => 'Próxima revisión';

  @override
  String get maintenance_next_date_label => 'Próxima fecha';

  @override
  String get maintenance_next_odometer_label => 'Próximo odómetro';

  @override
  String get maintenance_expired_label => 'vencido';

  @override
  String get maintenance_modeScheduled => 'Programado';

  @override
  String get maintenance_statusOverdue => 'Vencido';

  @override
  String get garage_viewMaintenanceHistory => 'Ver historial de mantenimientos';

  @override
  String get garage_completedServiceBadge => 'HECHO';

  @override
  String get garage_otherVehiclesSection => 'OTROS VEHÍCULOS';

  @override
  String get garage_upToDate => 'Al día';

  @override
  String garage_upcomingCount(int count) {
    return '$count próximo';
  }

  @override
  String get garage_mainVehicleBadge => 'Principal';

  @override
  String get garage_odometerLabel => 'odómetro';

  @override
  String get garage_healthUpcoming => 'Próximo';

  @override
  String get garage_tapForDetail => 'Toca para ver detalle del vehículo';

  @override
  String get garage_seeDetail => 'Ver detalle';

  @override
  String get notification_loadMore => 'Cargar más notificaciones';

  @override
  String get notification_loadError =>
      'No se pudieron cargar las notificaciones';

  @override
  String get notification_loadErrorSubtitle =>
      'Verifica tu conexión a internet e intenta de nuevo.';

  @override
  String get notification_soat30d_title => 'SOAT vence en 30 días';

  @override
  String get notification_soat7d_title => 'Tu SOAT vence en 7 días';

  @override
  String get notification_soatDayOf_title => 'Tu SOAT vence hoy';

  @override
  String notification_soat_subtitle(String vehicleName) {
    return '$vehicleName · Renuévalo para evitar multas';
  }

  @override
  String notification_soatDayOf_subtitle(String vehicleName) {
    return '$vehicleName · Renueva antes de salir';
  }

  @override
  String get notification_newRegistration_title => 'Nueva inscripción';

  @override
  String notification_newRegistration_subtitle(
    String riderName,
    String eventName,
  ) {
    return '$riderName quiere unirse a \"$eventName\"';
  }

  @override
  String get notification_approved_title => 'Inscripción aprobada';

  @override
  String notification_approved_subtitle(String eventName) {
    return 'Estás inscrito a \"$eventName\"';
  }

  @override
  String get notification_rejected_title => 'Inscripción rechazada';

  @override
  String notification_rejected_subtitle(String eventName) {
    return 'Tu solicitud para \"$eventName\" no fue aprobada';
  }

  @override
  String notification_bell_unread_label(int count) {
    return '$count notificaciones sin leer';
  }

  @override
  String get notification_bell_label => 'Notificaciones';

  @override
  String notification_item_accessibility_label(String title, String time) {
    return 'Notificación: $title, $time';
  }

  @override
  String get soat_page_upload_title => 'Subir SOAT';

  @override
  String get soat_page_status_title => 'Mi SOAT';

  @override
  String soat_upload_subtitle(String vehicleName) {
    return 'Selecciona cómo quieres subir tu SOAT para $vehicleName.';
  }

  @override
  String soat_manual_subtitle(String vehicleName) {
    return 'Ingresa los datos del SOAT para $vehicleName. Puedes subir el documento más adelante.';
  }

  @override
  String get soat_source_camera => 'Cámara';

  @override
  String get soat_source_gallery => 'Galería';

  @override
  String get soat_source_pdf => 'Archivo PDF';

  @override
  String get soat_source_manual => 'Ingresar manualmente';

  @override
  String get soat_scan_button => 'Escanear SOAT';

  @override
  String get soat_scan_sheet_title => 'Escanear documento';

  @override
  String get soat_scan_loading => 'Leyendo documento…';

  @override
  String get soat_scan_banner =>
      'Datos extraídos del documento — revisa antes de guardar';

  @override
  String get soat_scan_banner_review =>
      'Revisa con cuidado los campos resaltados antes de guardar';

  @override
  String get soat_scan_field_hint => 'Dato extraído del documento';

  @override
  String get soat_autofill_banner_title => 'Detectamos los datos de tu SOAT';

  @override
  String get soat_autofill_banner_subtitle =>
      'Puedes autocompletar el formulario y revisar antes de guardar';

  @override
  String get soat_autofill_banner_button => 'Autocompletar campos';

  @override
  String get soat_scan_error_unreadable =>
      'No pudimos leer el documento, ingresa los datos manualmente';

  @override
  String get soat_scan_error_permission =>
      'Necesitamos permiso de cámara o archivos para escanear el documento';

  @override
  String get soat_field_policy_number => 'N.° de póliza';

  @override
  String get soat_field_insurer => 'Aseguradora';

  @override
  String get soat_field_start_date => 'Fecha inicio';

  @override
  String get soat_field_expiry_date => 'Fecha vencimiento';

  @override
  String get soat_save_data_btn => 'Guardar datos';

  @override
  String get soat_saving => 'Guardando…';

  @override
  String get soat_manual_note =>
      'Puedes subir el documento físico más adelante desde el detalle del vehículo.';

  @override
  String get soat_status_no_soat => 'Sin registrar';

  @override
  String get soat_status_valid => 'Vigente';

  @override
  String get soat_status_expiring_soon => 'Por vencer';

  @override
  String get soat_status_expired => 'Vencido';

  @override
  String get soat_valid_title => 'Tu SOAT está al día';

  @override
  String get soat_expiring_title => 'Tu SOAT vence pronto';

  @override
  String get soat_expired_title => 'Tu SOAT está vencido';

  @override
  String soat_valid_days_remaining(int count) {
    return '$count días restantes';
  }

  @override
  String soat_expiring_days_remaining(int count) {
    return '$count días restantes';
  }

  @override
  String soat_expired_days_ago(int count) {
    return 'Venció hace $count días';
  }

  @override
  String get soat_expiring_warning =>
      'Te notificaremos 7 días antes del vencimiento. Renueva tu SOAT con anticipación para evitar multas.';

  @override
  String get soat_expired_warning =>
      'Circular sin SOAT vigente es una infracción. Renueva tu seguro lo antes posible.';

  @override
  String get soat_renew_btn => 'Registrar nuevo SOAT';

  @override
  String get soat_view_document => 'Ver documento';

  @override
  String get soat_edit_btn => 'Editar';

  @override
  String get soat_edit_title => 'Editar SOAT';

  @override
  String get soat_doc_tap_to_open => 'Toca para abrir';

  @override
  String get soat_doc_attached_title => 'Documento adjunto';

  @override
  String get soat_doc_replace => 'Reemplazar archivo';

  @override
  String get soat_doc_change => 'Cambiar archivo';

  @override
  String get soat_doc_add_label => 'Agregar documento SOAT';

  @override
  String get soat_doc_add_hint => 'Opcional · Imagen o PDF';

  @override
  String get soat_document_not_recognized =>
      'Parece que este documento no es un SOAT. Verifica el archivo o completa los datos manualmente.';

  @override
  String get soat_add_doc_sheet_title => 'Agregar documento';

  @override
  String get soat_add_doc_camera_subtitle => 'Toma una foto del documento';

  @override
  String get soat_add_doc_gallery_subtitle => 'Elige una imagen de tu galería';

  @override
  String get soat_add_doc_pdf_subtitle => 'Selecciona un archivo PDF';

  @override
  String get soat_upload_error =>
      'Error al subir. Archivo demasiado grande (máx. 10 MB).';

  @override
  String get soat_delete_button => 'Eliminar SOAT';

  @override
  String get soat_delete_confirm_title => '¿Eliminar SOAT?';

  @override
  String get soat_delete_confirm_message =>
      'Se eliminará la información del SOAT de este vehículo. Esta acción no se puede deshacer.';

  @override
  String get soat_deleted_success => 'SOAT eliminado';

  @override
  String get event_draftBadge => 'Borrador';

  @override
  String get draft_myDraftsTitle => 'Mis borradores';

  @override
  String get draft_noDrafts => 'No tienes borradores';

  @override
  String get draft_noDraftsHint =>
      'Guarda un evento como borrador para editarlo y publicarlo después';

  @override
  String get draft_publish => 'Publicar evento';

  @override
  String get route_typeLabel => 'Tipo de ruta';

  @override
  String get route_simpleLabel => 'Ruta simple (A→B)';

  @override
  String get route_customLabel => 'Ruta personalizada';

  @override
  String get route_builder_title => 'Crear ruta personalizada';

  @override
  String get route_builder_search_placeholder => 'Buscar un lugar...';

  @override
  String get route_builder_search_placeholder_disabled =>
      'Límite de 9 puntos alcanzado';

  @override
  String get route_builder_section_title => 'PUNTOS DE RUTA';

  @override
  String route_builder_counter(int count) {
    return '$count/9 puntos';
  }

  @override
  String get route_builder_empty_hint => 'Agrega puntos para construir tu ruta';

  @override
  String get route_builder_continue => 'Continuar';

  @override
  String get route_builder_limit_banner =>
      'Has alcanzado el límite de 9 puntos. Elimina uno para agregar otro.';

  @override
  String get route_builder_pick_mode_button => 'Seleccionar en mapa';

  @override
  String get route_builder_pick_mode_confirm => 'Añadir este punto';

  @override
  String get route_placeSearchError => 'No se pudo cargar sugerencias';

  @override
  String get route_noPlacesFound => 'No se encontraron resultados';

  @override
  String get map_pickLocation => 'Seleccionar en el mapa';

  @override
  String get map_dragToPosition => 'Mueve el mapa para posicionar el punto';

  @override
  String get map_confirmLocation => 'Confirmar ubicación';

  @override
  String get map_searchingAddress => 'Buscando dirección...';

  @override
  String get map_addressNotFound => 'Dirección no encontrada';

  @override
  String get event_route_meeting_point_hint => 'Punto de encuentro';

  @override
  String get event_route_destination_hint => 'Destino final';

  @override
  String get vehicle_soat_camera_button => 'Cámara';

  @override
  String get vehicle_soat_file_button => 'PDF';

  @override
  String get vehicle_soat_gallery_button => 'Galería';

  @override
  String get vehicle_soat_option_manual_cta => 'Completar formulario';

  @override
  String get vehicle_soat_option_manual_desc =>
      'Completa los datos del SOAT de forma manual sin necesidad de subir un documento';

  @override
  String get vehicle_soat_option_manual_title => 'Ingresar manualmente';

  @override
  String get vehicle_soat_option_upload_desc =>
      'Sube una foto o el PDF del SOAT y leeremos los datos automáticamente para ti';

  @override
  String get vehicle_soat_option_upload_title => 'Escanea tu SOAT';

  @override
  String get vehicle_soat_upload_question => '¿Cómo deseas registrar tu SOAT?';

  @override
  String get vehicle_soat_upload_subtitle =>
      'Selecciona una opción para actualizar el SOAT de tu vehículo';
}
