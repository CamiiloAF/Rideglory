/// Events feature string constants
class EventStrings {
  EventStrings._();

  // Page titles
  static const String events = 'Eventos';
  static const String myEvents = 'Mis Eventos';
  static const String createEvent = 'Crear Evento';
  static const String editEvent = 'Editar Evento';
  static const String eventDetail = 'Detalle del Evento';
  static const String deleteEvent = 'Eliminar Evento';

  // Event form section titles
  static const String basicInfo = 'Información básica';
  static const String dateAndTime = 'Fecha y hora';
  static const String locations = 'Ubicaciones';
  static const String eventDetails = 'Detalles del evento';
  static const String recommendations = 'Recomendaciones';

  // Form field labels
  static const String eventName = 'Nombre del evento';
  static const String eventDescription = 'Descripción';
  static const String eventCity = 'Ciudad';
  static const String startDate = 'Fecha de inicio';
  static const String endDate = 'Fecha de fin (opcional)';
  static const String dateRange = 'Rango de fechas del evento';
  static const String isMultiDay = 'Es un evento de varios días';
  static const String meetingTime = 'Hora de encuentro';
  static const String difficulty = 'Dificultad';
  static const String eventType = 'Tipo de evento';
  static const String meetingPoint = 'Punto de encuentro';
  static const String meetingPointLocation = 'Ubicación del punto de encuentro';
  static const String destination = 'Destino';
  static const String destinationLocation = 'Ubicación del destino';
  static const String latitude = 'Latitud';
  static const String longitude = 'Longitud';
  static const String isMultiBrand = 'Evento multimarca (abierto a todos)';
  static const String allowedBrands = 'Marcas permitidas';
  static const String allowedBrandsHint = 'Honda, Yamaha, Kawasaki...';
  static const String allowedBrandsHelper =
      'Separar con coma. Dejar vacío si acepta todas las marcas.';
  static const String addBrand = 'Agregar marca';
  static const String price = 'Precio del evento (opcional)';
  static const String freeEvent = 'Evento gratuito';
  static const String recommendationsHint =
      'Escribe recomendaciones, notas importantes, links, etc.';
  static const String recommendationsLabel = 'Recomendaciones del organizador';

  static const String startDateMustBeBeforeEndDate =
      'La fecha de inicio debe ser anterior a la fecha de fin';

  // Difficulty labels
  static const String difficultyOne = '🌶 Fácil';
  static const String difficultyTwo = '🌶🌶 Moderado';
  static const String difficultyThree = '🌶🌶🌶 Intermedio';
  static const String difficultyFour = '🌶🌶🌶🌶 Difícil';
  static const String difficultyFive = '🌶🌶🌶🌶🌶 Muy difícil';

  // Event types
  static const String offRoad = 'Off-Road';
  static const String onRoad = 'On-Road';
  static const String exhibition = 'Exhibición';
  static const String charitable = 'Benéfico';

  // Save button
  static const String saveEvent = 'Guardar Evento';
  static const String updateEvent = 'Actualizar Evento';

  // Messages
  static const String eventCreatedSuccess = 'Evento creado exitosamente';
  static const String eventUpdatedSuccess = 'Evento actualizado exitosamente';
  static const String eventDeletedSuccess = 'Evento eliminado exitosamente';
  static const String deleteEventMessage =
      '¿Estás seguro de que deseas eliminar este evento?\nEsta acción no se puede deshacer.';
  static const String noEvents = 'No hay eventos disponibles';
  static const String noEventsDescription =
      'Sé el primero en crear un evento para la comunidad';
  static const String noMyEvents = 'No has creado eventos';
  static const String noMyEventsDescription =
      'Crea tu primer evento y compártelo con la comunidad';

  // Search & Filters
  static const String searchEvents = 'Buscar eventos';
  static const String filters = 'Filtros';
  static const String applyFilters = 'Aplicar filtros';
  static const String clearFilters = 'Limpiar filtros';
  static const String filterByType = 'Tipo de evento';
  static const String filterByDifficulty = 'Dificultad';
  static const String filterByCity = 'Ciudad';
  static const String filterByDateRange = 'Rango de fechas';
  static const String filterByFreeOnly = 'Solo eventos gratuitos';
  static const String filterByMultiBrand = 'Solo multimarca';

  // Detail & actions
  static const String joinEvent = 'Inscribirse';
  static const String editRegistration = 'Editar inscripción';
  static const String cancelRegistration = 'Cancelar inscripción';
  static const String viewRecommendations = 'Ver recomendaciones';
  static const String viewAttendees = 'Ver inscritos';
  static const String openInMaps = 'Abrir en Google Maps';
  static const String meetingPointLabel = 'Punto de encuentro';
  static const String destinationLabel = 'Destino';
  static const String dateLabel = 'Fecha';
  static const String timeLabel = 'Hora de encuentro';
  static const String priceLabel = 'Precio';
  static const String free = 'Gratuito';
  static const String difficultyLabel = 'Dificultad';
  static const String typeLabel = 'Tipo';
  static const String organizer = 'Organizador';
  static const String brandRestriction = 'Marcas';
  static const String allBrands = 'Abierto a todos';

  // Status labels
  // TODO USAR ESTO
  static const String pending = 'Pendiente';
  static const String approved = 'Aprobado';
  static const String rejected = 'Rechazado';
  static const String cancelled = 'Cancelado';
  static const String readyForEdit = 'Listo para editar';

  // Registration status descriptions
  static const String pendingDescription =
      'Tu inscripción está pendiente de aprobación';
  static const String approvedDescription = '¡Tu inscripción fue aprobada!';
  static const String rejectedDescription =
      'Tu inscripción fue rechazada. No puedes volver a inscribirte a este evento.';
  static const String cancelledDescription = 'Cancelaste tu inscripción.';
  static const String readyForEditDescription =
      'El organizador habilitó la edición de tu inscripción.';

  // Attendees
  static const String attendees = 'Inscritos';
  static const String attendeesCount = 'personas inscritas';
  static const String approveRegistration = 'Aprobar';
  static const String rejectRegistration = 'Rechazar';
  static const String setReadyForEdit = 'Habilitar edición';
  static const String callAttendee = 'Llamar';
  static const String emailAttendee = 'Enviar correo';
  static const String whatsappAttendee = 'WhatsApp';
  static const String noAttendees = 'No hay inscritos aún';

  // Cancel confirmation
  static const String cancelRegistrationTitle = 'Cancelar inscripción';
  static const String cancelRegistrationMessage =
      '¿Estás seguro de que deseas cancelar tu inscripción? Esta acción no se puede deshacer. Podrás inscribirte nuevamente en cualquier momento.';
  static const String cancelRegistrationSuccess =
      'Tu inscripción fue cancelada exitosamente';

  // Dynamic confirmation messages
  static String approveConfirmMessage(String name) =>
      '¿Aprobar la inscripción de $name?';
  static String rejectConfirmMessage(String name) =>
      '¿Rechazar la inscripción de $name?';
  static String setReadyForEditConfirmMessage(String name) =>
      '¿Habilitar edición para $name?';

  // Error messages
  static const String errorLoadingEvents = 'Error al cargar los eventos';
  static const String errorSavingEvent = 'Error al guardar el evento';
  static const String errorDeletingEvent = 'Error al eliminar el evento';

  // Validation
  static const String nameRequired = 'El nombre es requerido';
  static const String descriptionRequired = 'La descripción es requerida';
  static const String cityRequired = 'La ciudad es requerida';
  static const String dateRangeRequired =
      'Las fechas del evento son requeridas';
  static const String startDateRequired = 'La fecha de inicio es requerida';
  static const String meetingTimeRequired = 'La hora de encuentro es requerida';
  static const String meetingPointRequired =
      'El punto de encuentro es requerido';
  static const String destinationRequired = 'El destino es requerido';
  static const String difficultyRequired = 'La dificultad es requerida';
  static const String eventTypeRequired = 'El tipo de evento es requerido';
  static const String minCharacters = 'Mínimo 3 caracteres';
  static const String invalidLatitude = 'Latitud inválida (-90 a 90)';
  static const String invalidLongitude = 'Longitud inválida (-180 a 180)';
  static const String invalidPrice = 'Precio inválido';
}
