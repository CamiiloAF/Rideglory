/// Maintenance feature string constants
class MaintenanceStrings {
  MaintenanceStrings._();

  // Page titles
  static const String maintenance = 'Mantenimiento';
  static const String maintenances = 'Mantenimientos';
  static const String addMaintenance = 'Agregar mantenimiento';
  static const String editMaintenance = 'Editar mantenimiento';
  static const String deleteMaintenance = 'Eliminar mantenimiento';
  static const String maintenanceHistory = 'Ver historial';
  static const String reminders = 'Recordatorios';
  static const String maintenanceDetail = 'Detalle de mantenimiento';
  static const String newRecord = 'Nuevo Registro';
  static const String editRecord = 'Editar Registro';

  // Messages
  static const String deleteMaintenanceMessage =
      '¿Estás seguro de que deseas eliminar este mantenimiento?\nEsta acción no se puede deshacer.';
  static const String noMaintenances = 'No hay mantenimientos registrados';
  static const String noMaintenancesDescription =
      'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo';
  static const String receiveMaintenanceAlert =
      'Recibe una notificación cuando se acerque el próximo mantenimiento';

  static const String mileageAlert = 'Alerta por kilometraje';
  static const String mileageAlertHint =
      'Notificar cuando falten 500 km para el mantenimiento';

  static const String dateAlert = 'Alerta por fecha';
  static const String dateAlertHint =
      'Notificar una semana antes de la fecha programada';

  static const String maintenanceDeletedSuccessfully =
      'Mantenimiento eliminado correctamente';
  static const String errorLoadingRecords = 'Error cargando registros';
  static const String noRecordsYet = 'Aún no hay registros';

  // Form fields
  static const String maintenanceType = 'Tipo de Mantenimiento';
  static const String maintenanceDate = 'Fecha de Mantenimiento';
  static const String maintenanceNotes = 'Notas / Observaciones';
  static const String maintenanceCost = 'Costo del Mantenimiento';
  static const String maintenanceMileage = 'Kilometraje Actual';
  static const String nextMaintenance = 'Próximo mantenimiento';
  static const String nextMaintenanceMileage =
      'Kilometraje del próximo mantenimiento';
  static String get distanceUnit => 'Unidad';
  static const String totalCost = 'Costo total';
  static const String serviceNotes = 'Notas de servicio';
  static const String estimatedDate = 'Fecha estimada';
  static const String suggested = 'Sugerido';
  static const String routine = 'Rutina';
  static String performedOn(String date) => 'Completado el $date';
  static const String alertByMileage = 'Por kilometraje';
  static const String alertByDate = 'Por fecha';
  static const String mileageAlertBefore = '500 km antes';
  static const String dateAlertBefore = '7 días antes';

  // Status
  static const String urgent = 'Urgente';
  static const String urgentOnly = 'Solo urgentes';

  // Filters
  static const String filters = 'Filtros';
  static const String myVehicles = 'Mis Vehículos';
  static const String applyFilters = 'Aplicar filtros';
  static const String clearFilters = 'Limpiar filtros';

  // Mileage
  static const String mileage = 'Kilometraje';
  static const String currentMileage = 'Kilometraje Actual';
  static const String updateMileage = 'Actualizar kilometraje';
  static const String mileageUnit = 'Unidad';
  static const String kilometers = 'Kilómetros';
  static const String miles = 'Millas';
  static const String km = 'km';
  static const String mi = 'mi';
  static const String current = 'Actual:';
  static const String maintenanceLabel = 'Mantenimiento:';
  static const String mileageGreaterThanCurrent =
      'El kilometraje del mantenimiento es mayor al kilometraje actual del vehículo.';
  static const String updateVehicleMileageQuestion =
      '¿Deseas actualizar el kilometraje del vehículo?';

  // Months abbreviations
  static const String monthJan = 'Ene';
  static const String monthFeb = 'Feb';
  static const String monthMar = 'Mar';
  static const String monthApr = 'Abr';
  static const String monthMay = 'May';
  static const String monthJun = 'Jun';
  static const String monthJul = 'Jul';
  static const String monthAug = 'Ago';
  static const String monthSep = 'Sep';
  static const String monthOct = 'Oct';
  static const String monthNov = 'Nov';
  static const String monthDec = 'Dic';

  // Actions
  static const String addMaintenance_ = 'Agregar mantenimiento';
  static const String addMaintenanceAction = 'Agregar mantenimiento';
  static const String viewHistory = 'Ver historial';
  static const String saveMaintenance = 'Guardar Registro';
  static const String saveOnly = 'Solo guardar';
  static const String update = 'Actualizar';

  // Filters labels
  static const String sortBy = 'Ordenar por';
  static const String maintenanceTypes = 'Tipos de mantenimiento';
  static const String vehicles = 'Vehículos';
  static const String dateRange = 'Rango de fechas';
  static const String startDate = 'Inicio';
  static const String endDate = 'Fin';
  static const String sortByNextMaintenance = 'Próximo mantenimiento';
  static const String sortByDate = 'Fecha de realización';
  static const String sortByName = 'Nombre';
  static const String urgentOnlyDescription =
      'Próximo mantenimiento en 7 días o menos';

  // Card labels
  static const String vehicle = 'Vehículo';
  static const String selectVehicle = 'Seleccionar Vehículo';
  static const String chooseVehicleForMaintenance =
      'Elige el vehículo para este mantenimiento';
  static const String next = 'Próximo';
  static const String calculateRemainingDistance =
      'Calcular distancia restante';
  static String remainingDistance(String distance, String unit) =>
      '$distance $unit restantes';

  // Form field labels
  static const String maintenanceName = 'Nombre del Mantenimiento';
  static const String nextMaintenanceDate = 'PRÓXIMA FECHA';
  static const String maintenanceDateLabel = 'Fecha de Servicio';
  static const String nextMaintenanceMileageLabel = 'PRÓXIMO KM';

  // Validation messages
  static const String nameRequired = 'El nombre es requerido';
  static const String minCharacters = 'Mínimo 3 caracteres';
  static const String typeRequired = 'El tipo es requerido';

  // Alerts & Notifications
  static const String remindersLabel = 'Recibe recordatorios automáticos';
  static const String nextServiceAlerts = 'Alertas de próximo servicio';
  static const String alertsConfiguration = 'Configuración de alertas';
  static const String alertsActivatedDesc =
      'Las alertas están activadas para este mantenimiento.';

  // Search
  static const String searchMaintenances =
      'Buscar por nombre del mantenimiento';

  // Vehicle selection
  static const String allVehicles = 'Todos los vehículos';

  // List
  static const String recentRecords = 'Registros recientes';
  static const String filter = 'Filtrar';
}
