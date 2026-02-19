/// Maintenance feature string constants
class MaintenanceStrings {
  MaintenanceStrings._();

  // Page titles
  static const String maintenance = 'Mantenimiento';
  static const String maintenances = 'Mantenimientos';
  static const String addMaintenance = 'Agregar Mantenimiento';
  static const String editMaintenance = 'Editar Mantenimiento';
  static const String deleteMaintenance = 'Eliminar mantenimiento';
  static const String maintenanceHistory = 'Ver Historial';
  static const String reminders = 'Recordatorios';

  // Messages
  static const String deleteMaintenanceMessage =
      '¿Estás seguro de que deseas eliminar este mantenimiento?\nEsta acción no se puede deshacer.';
  static const String noMaintenances = 'No hay mantenimientos registrados';
  static const String noMaintenancesDescription =
      'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo';
  static const String maintenanceDeletedSuccessfully =
      'Mantenimiento eliminado exitosamente';

  // Form fields
  static const String maintenanceType = 'Tipo de mantenimiento';
  static const String maintenanceDate = 'Fecha de mantenimiento';
  static const String maintenanceNotes = 'Notas';
  static const String maintenanceCost = 'Costo';
  static const String maintenanceMileage = 'Kilometraje';
  static const String nextMaintenance = 'Próximo mantenimiento';
  static const String nextMaintenanceMileage =
      'Kilometraje del próximo mantenimiento';
  static String get distanceUnit => 'Unidad';

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
  static const String currentMileage = 'Kilometraje actual';
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
  static const String addMaintenance_ = 'Agregar Mantenimiento';
  static const String addMaintenanceAction = 'Agregar mantenimiento';
  static const String viewHistory = 'Ver Historial';
  static const String saveMaintenance = 'Guardar Mantenimiento';
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
  static const String maintenanceName = 'Nombre del mantenimiento';
  static const String nextMaintenanceDate = 'Fecha del próximo mantenimiento';
  static const String maintenanceDateLabel = 'Fecha del mantenimiento';

  // Validation messages
  static const String nameRequired = 'El nombre es requerido';
  static const String minCharacters = 'Mínimo 3 caracteres';
  static const String typeRequired = 'El tipo es requerido';

  // Alerts & Notifications
  static const String receiveMaintenanceAlert =
      'Recibir alerta de mantenimiento';

  // Search
  static const String searchMaintenances =
      'Buscar por nombre del mantenimiento';
}
