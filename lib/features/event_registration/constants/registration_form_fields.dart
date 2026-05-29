abstract class RegistrationFormFields {
  static const String fullName = 'fullName';
  static const String identificationNumber = 'identificationNumber';
  static const String birthDate = 'birthDate';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String residenceCity = 'residenceCity';
  static const String eps = 'eps';
  static const String medicalInsurance = 'medicalInsurance';
  static const String bloodType = 'bloodType';
  static const String emergencyContactName = 'emergencyContactName';
  static const String emergencyContactPhone = 'emergencyContactPhone';
  static const String vehicleId = 'vehicleId';
  static const String saveToProfile = 'saveToProfile';
}

/// Field names grouped by wizard step, in display order. Used to validate only
/// the current step's fields before advancing in the registration wizard.
abstract class RegistrationWizardSteps {
  static const List<List<String>> fieldsByStep = <List<String>>[
    <String>[
      RegistrationFormFields.fullName,
      RegistrationFormFields.identificationNumber,
      RegistrationFormFields.birthDate,
      RegistrationFormFields.phone,
      RegistrationFormFields.email,
      RegistrationFormFields.residenceCity,
    ],
    <String>[RegistrationFormFields.eps, RegistrationFormFields.bloodType],
    <String>[
      RegistrationFormFields.emergencyContactName,
      RegistrationFormFields.emergencyContactPhone,
    ],
    <String>[RegistrationFormFields.vehicleId],
  ];

  static int get stepCount => fieldsByStep.length;
}
