abstract class RegistrationStrings {
  RegistrationStrings._();

  // Page titles
  static const String registrationPageTitle = 'Inscripción al Evento';
  static const String registrationForm = 'Formulario de inscripción';
  static const String myRegistrations = 'Mis inscripciones';
  static const String editRegistration = 'Editar inscripción';

  // Section titles (card headers)
  static const String personalData = 'Datos Personales';
  static const String medicalInfo = 'Información Médica';
  static const String emergencyContactRequired = 'Contacto de emergencia';
  static const String vehicleData = 'Datos del Vehículo';
  static const String personalInfo = 'Información personal';
  static const String emergencyContact = 'Contacto de emergencia';
  static const String vehicleInfo = 'Información del vehículo';
  static const String vehicleRegistered = 'Vehículo registrado';

  // Form field labels
  static const String firstName = 'Nombres';
  static const String lastName = 'Apellidos';
  static const String identificationNumber = 'Identificación';
  static const String birthDate = 'Fecha Nacimiento';
  static const String phone = 'Celular';
  static const String email = 'Correo Electrónico';
  static const String residenceCity = 'Ciudad Residencia';
  static const String eps = 'EPS';
  static const String medicalInsurance = 'Medicina Prepagada (Opcional)';
  static const String bloodType = 'RH';
  static const String emergencyContactName = 'Nombre completo contacto';
  static const String emergencyContactPhone = 'Celular contacto';
  static const String vehicleBrand = 'Marca';
  static const String vehicleReference = 'Referencia';
  static const String licensePlate = 'Placa';
  static const String vin = 'VIN (Serial)';

  // Hints
  static const String firstNameHint = 'Ej. Juan Carlos';
  static const String lastNameHint = 'Ej. Pérez Rodriguez';
  static const String identificationHint = 'CC/TI/CE';
  static const String birthDateHint = 'mm/dd/yyyy';
  static const String phoneHint = '300 000 0000';
  static const String residenceCityHint = 'Busca tu ciudad';
  static const String emailHint = 'usuario@ejemplo.com';
  static const String epsHint = 'Nombre EPS';
  static const String bloodTypeSelect = 'Seleccione';
  static const String bloodTypeHint = 'RH';
  static const String emergencyContactNameHint = 'Ej. María García';
  static const String emergencyContactPhoneHint = '300 000 0000';
  static const String medicalInsuranceHint = 'Entidad de medicina prepagada';
  static const String vehicleBrandHint = 'Ej. Yamaha';
  static const String vehicleReferenceHint = 'Ej. MT-09';
  static const String licensePlateHint = 'ABC-12D';
  static const String vinHint = '17 Caracteres';

  // Vehicle preload
  static const String preloadFromVehicle = 'Precargar vehículo';
  static const String selectVehicleToPreload =
      'Selecciona un vehículo para precargar la información';

  // Form actions
  static const String clearForm = 'Limpiar formulario';

  // Save button
  static const String sendRegistration = 'Enviar inscripción';
  static const String updateRegistration = 'Actualizar inscripción';

  // Messages
  static const String registrationSentSuccess =
      'Inscripción enviada exitosamente. Está pendiente de aprobación.';
  static const String registrationUpdatedSuccess =
      'Inscripción actualizada exitosamente.';
  static const String registrationCancelledSuccess =
      'Inscripción cancelada exitosamente.';
  static const String noRegistrations = 'No tienes inscripciones';
  static const String noRegistrationsDescription =
      'Explora los eventos disponibles y únete a la aventura';

  // Validation
  static const String firstNameRequired = 'Los nombres son requeridos';
  static const String lastNameRequired = 'Los apellidos son requeridos';
  static const String idRequired = 'El número de identificación es requerido';
  static const String idInvalidLength =
      'La cédula debe tener entre 6 y 10 dígitos (estándar Colombia)';
  static const String birthDateRequired = 'La fecha de nacimiento es requerida';
  static const String phoneRequired = 'El celular es requerido';
  static const String phoneInvalidLength =
      'El celular debe tener 10 dígitos (estándar Colombia)';
  static const String emailRequired = 'El correo electrónico es requerido';
  static const String emailInvalid = 'Correo electrónico inválido';
  static const String residenceCityRequired =
      'La ciudad de residencia es requerida';
  static const String epsRequired = 'La EPS es requerida';
  static const String bloodTypeRequired = 'El tipo de sangre es requerido';
  static const String emergencyContactNameRequired =
      'El nombre del contacto de emergencia es requerido';
  static const String emergencyContactPhoneRequired =
      'El celular del contacto de emergencia es requerido';
  static const String emergencyContactPhoneInvalidLength =
      'El celular del contacto debe tener 10 dígitos (estándar Colombia)';
  static const String vehicleBrandRequired =
      'La marca del vehículo es requerida';
  static const String vehicleReferenceRequired =
      'La referencia del vehículo es requerida';
  static const String licensePlateRequired = 'La placa es requerida';
  static const String minCharacters = 'Mínimo 2 caracteres';

  // Error messages
  static const String errorLoadingRegistrations =
      'Error al cargar las inscripciones';
  static const String errorSendingRegistration =
      'Error al enviar la inscripción';

  // Actions
  static const String viewDetail = 'Ver detalle';
  static const String viewEvent = 'Ver evento';
  static const String goToEvents = 'Ir a eventos';
  static const String details = 'Detalles';
  static const String myRegistration = 'Mi registro';
  static const String reason = 'Motivo';
  static const String reRegister = 'Re-inscribirse';

  // Detail page
  static const String registrationDetail = 'Detalle de inscripción';
  static const String registrationDetailTitle = 'Detalle de Registro';
  static const String eventInfo = 'Información del evento';
  static const String inscriptionDate = 'Fecha de inscripción';
  static const String errorLoadingEvent = 'Error al cargar el evento';

  // Detail page labels (design)
  static const String fullNameLabel = 'Nombres Completos';
  static const String identificationIdLabel = 'Identificación (ID)';
  static const String birthDateLabel = 'Fecha de Nacimiento';
  static const String bloodTypeLabel = 'Tipo de Sangre';
  static const String epsOrInsuranceLabel = 'EPS / Seguro';
  static const String brandModelLabel = 'Marca / Modelo';
  static const String cityLabel = 'Ciudad';

  // Detail page actions
  static const String reject = 'Rechazar';
  static const String approve = 'Aprobar';
}
