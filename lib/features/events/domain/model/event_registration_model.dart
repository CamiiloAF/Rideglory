enum RegistrationStatus {
  pending('Pendiente'),
  approved('Aprobado'),
  rejected('Rechazado'),
  cancelled('Cancelado'),
  readyForEdit('Listo para editar');

  final String label;
  const RegistrationStatus(this.label);
}

enum BloodType {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-'),
  oPositive('O+'),
  oNegative('O-');

  final String label;
  const BloodType(this.label);
}

class EventRegistrationModel {
  final String? id;
  final String eventId;
  final String userId;
  final RegistrationStatus status;

  // Personal info
  final String firstName;
  final String lastName;
  final String identificationNumber;
  final DateTime birthDate;
  final String phone;
  final String email;
  final String residenceCity;

  // Medical info
  final String eps;
  final String? medicalInsurance;
  final BloodType bloodType;

  // Emergency contact
  final String emergencyContactName;
  final String emergencyContactPhone;

  // Vehicle info
  final String vehicleBrand;
  final String vehicleReference;
  final String licensePlate;
  final String? vin;

  final DateTime? createdDate;
  final DateTime? updatedDate;

  const EventRegistrationModel({
    this.id,
    required this.eventId,
    required this.userId,
    this.status = RegistrationStatus.pending,
    required this.firstName,
    required this.lastName,
    required this.identificationNumber,
    required this.birthDate,
    required this.phone,
    required this.email,
    required this.residenceCity,
    required this.eps,
    this.medicalInsurance,
    required this.bloodType,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.vehicleBrand,
    required this.vehicleReference,
    required this.licensePlate,
    this.vin,
    this.createdDate,
    this.updatedDate,
  });

  String get fullName => '$firstName $lastName';

  EventRegistrationModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    RegistrationStatus? status,
    String? firstName,
    String? lastName,
    String? identificationNumber,
    DateTime? birthDate,
    String? phone,
    String? email,
    String? residenceCity,
    String? eps,
    String? medicalInsurance,
    BloodType? bloodType,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? vehicleBrand,
    String? vehicleReference,
    String? licensePlate,
    String? vin,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return EventRegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      residenceCity: residenceCity ?? this.residenceCity,
      eps: eps ?? this.eps,
      medicalInsurance: medicalInsurance ?? this.medicalInsurance,
      bloodType: bloodType ?? this.bloodType,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleReference: vehicleReference ?? this.vehicleReference,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventRegistrationModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
