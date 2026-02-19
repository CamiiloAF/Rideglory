/// Vehicles feature string constants
class VehicleStrings {
  VehicleStrings._();

  // Page titles
  static const String vehicles = 'Vehículos';
  static const String myVehicles = 'Mis Vehículos';
  static const String addVehicle = 'Agregar Vehículo';
  static const String editVehicle = 'Editar Vehículo';
  static const String deleteVehicle = 'Eliminar Vehículo';

  // Actions
  static const String selectVehicle = 'Seleccionar vehículo';
  static const String changeVehicle = 'Cambiar vehículo';
  static const String setAsMainVehicle = 'Establecer como vehículo principal';
  static const String setAsMain = 'Establecer como principal';
  static const String archiveVehicle = 'Archivar';
  static const String unarchiveVehicle = 'Desarchivar';

  // Messages
  static const String deleteVehicleMessage =
      '¿Estás seguro de que deseas eliminar';
  static const String deleteVehicleWarning =
      'Esta acción eliminará todos los mantenimientos asociados a este vehículo y no se podrá deshacer.';
  static const String vehicleDeleted = 'Vehículo eliminado exitosamente';
  static const String vehicleSetAsMain = 'establecido como vehículo principal';
  static const String vehicleArchived = 'archivado';
  static const String vehicleUnarchived = 'desarchivado';
  static const String noVehicles = 'No tienes vehículos registrados';
  static const String noVehiclesAvailable = 'No hay vehículos disponibles';
  static const String mainVehicle = 'Vehículo principal';
  static const String thisWillBeMainVehicle = 'Este será tu vehículo principal';
  static const String archivedVehicle = 'Vehículo Archivado';
  static const String archivedVehicleMessage =
      'Este vehículo está archivado. ¿Deseas continuar editándolo?\nSi actualizas su información, el vehículo será desarchivado y volverá a estar disponible en tu lista de vehículos activos.';
  static const String exitSetup = '¿Salir de la configuración?';
  static const String exitSetupMessage =
      'Si sales ahora, perderás el progreso de la configuración del vehículo.';
  static const String completeRequiredFields =
      'Por favor completa todos los campos requeridos';
  static const String searchVehicles = 'Buscar por nombre, placa o marca';

  // Form fields
  static const String vehicleName = 'Nombre del vehículo';
  static const String vehicleType = 'Tipo de vehículo';
  static const String vehicleBrand = 'Marca';
  static const String vehicleModel = 'Modelo';
  static const String vehicleYear = 'Año';
  static const String vehiclePlate = 'Placa';
  static const String vehicleVin = 'VIN';

  // Hints
  static const String vehicleNameHint = 'ej., Mi Auto, Camioneta Familiar';
  static const String vehicleBrandHint = 'ej., Toyota';
  static const String vehicleModelHint = 'ej., Camry';
  static const String vehicleYearHint = 'ej., 2020';
  static const String vehiclePlateHint = 'ej., ABC-1234';
  static const String vehicleVinHint = 'Número de Identificación del Vehículo';

  // View states
  static const String viewArchived = 'Ver archivados';
  static const String showActiveVehicles = 'Mostrar activos';
  static const String addFirstVehicle =
      'Agrega tu primer vehículo para comenzar';
  static const String adjustSearch = 'Intenta ajustar la búsqueda';
  static const String archiveVehiclesDescription =
      'Archiva vehículos que ya no uses';

  // Tooltips
  static const String maintenancesTooltip = 'Mantenimientos';
  static const String addVehicleTooltip = 'Agregar vehículo';
  static const String removeVehicleTooltip = 'Eliminar vehículo';
  static const String addAnotherVehicleTooltip = 'Agregar otro vehículo';

  // Onboarding
  static const String welcome = '¡Bienvenido! 🎉';
  static const String addAtLeastOneVehicle =
      'Agrega al menos un vehículo para comenzar';
  static String vehicleCounter(int current, int total) =>
      'Vehículo $current de $total';
  static const String completeSetup = 'Completar configuración';

  // Validation messages
  static const String nameRequired = 'El nombre es requerido';
  static const String vehicleTypeRequired = 'El tipo de vehículo es requerido';
  static const String brandRequired = 'La marca es requerida';
  static const String yearRequired = 'El año es requerido';
  static const String minCharacters = 'Mínimo 3 caracteres';
  static const String invalidYear = 'Año inválido';

  // Additional form fields
  static const String purchaseDate = 'Fecha de compra';

  // Vehicle types
  static const String car = 'Carro';
  static const String motorcycle = 'Moto';

  // Units
  static const String kilometers = 'Kilómetros';
  static const String miles = 'Millas';
}
