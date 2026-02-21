/// Event registration feature string constants
class RegistrationStrings {
  RegistrationStrings._();

  // Page titles
  static const String registrationForm = 'Formulario de inscripción';
  static const String myRegistrations = 'Mis inscripciones';
  static const String editRegistration = 'Editar inscripción';

  // Section titles
  static const String personalInfo = 'Información personal';
  static const String medicalInfo = 'Información médica';
  static const String emergencyContact = 'Contacto de emergencia';
  static const String vehicleInfo = 'Información del vehículo';

  // Form field labels
  static const String firstName = 'Nombres';
  static const String lastName = 'Apellidos';
  static const String identificationNumber = 'Número de identificación';
  static const String birthDate = 'Fecha de nacimiento';
  static const String phone = 'Celular';
  static const String email = 'Correo electrónico';
  static const String residenceCity = 'Ciudad de residencia';
  static const String eps = 'EPS';
  static const String medicalInsurance =
      'Seguro médico / Medicina prepagada (opcional)';
  static const String bloodType = 'Tipo de sangre (RH)';
  static const String emergencyContactName = 'Nombre contacto de emergencia';
  static const String emergencyContactPhone = 'Celular contacto de emergencia';
  static const String vehicleBrand = 'Marca del vehículo';
  static const String vehicleReference = 'Referencia del vehículo';
  static const String licensePlate = 'Placa';
  static const String vin = 'VIN (opcional)';

  // Vehicle preload
  static const String preloadFromVehicle = 'Precargar desde vehículo';
  static const String selectVehicleToPreload =
      'Selecciona un vehículo para precargar la información';
  static const String preloadFromMainVehicle =
      'Precargar desde vehículo principal';

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
  static const String birthDateRequired = 'La fecha de nacimiento es requerida';
  static const String phoneRequired = 'El celular es requerido';
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
}
