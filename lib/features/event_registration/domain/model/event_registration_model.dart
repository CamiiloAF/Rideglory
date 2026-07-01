import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/event_registration/domain/model/vehicle_summary_model.dart';

enum RegistrationStatus {
  @JsonValue('PENDING')
  pending('Pendiente'),
  @JsonValue('APPROVED')
  approved('Aprobado'),
  @JsonValue('REJECTED')
  rejected('Rechazado'),
  @JsonValue('CANCELLED')
  cancelled('Cancelado'),
  @JsonValue('READY_FOR_EDIT')
  readyForEdit('Listo para editar');

  final String label;
  const RegistrationStatus(this.label);
}

enum BloodType {
  @JsonValue('A_POSITIVE')
  aPositive('A+'),
  @JsonValue('A_NEGATIVE')
  aNegative('A-'),
  @JsonValue('B_POSITIVE')
  bPositive('B+'),
  @JsonValue('B_NEGATIVE')
  bNegative('B-'),
  @JsonValue('AB_POSITIVE')
  abPositive('AB+'),
  @JsonValue('AB_NEGATIVE')
  abNegative('AB-'),
  @JsonValue('O_POSITIVE')
  oPositive('O+'),
  @JsonValue('O_NEGATIVE')
  oNegative('O-');

  final String label;
  const BloodType(this.label);
}

class EventRegistrationModel {
  final String? id;
  final String eventId;
  final String eventName;
  final String userId;
  final RegistrationStatus status;

  // Personal info
  final String fullName;
  final String identificationNumber;
  final DateTime birthDate;
  final String phone;
  final String email;
  final String residenceCity;

  // Medical info
  final String eps;
  final String? medicalInsurance;
  final BloodType? bloodType;

  // Emergency contact
  final String emergencyContactName;
  final String emergencyContactPhone;

  // Vehicle info
  final String? vehicleId;
  final VehicleSummaryModel? vehicleSummary;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Legal / privacy
  final bool shareMedicalInfo;
  final bool allowOrganizerContact;
  final DateTime? riskAcceptedAt;
  final String? riskAcceptanceVersion;

  const EventRegistrationModel({
    this.id,
    required this.eventId,
    required this.eventName,
    required this.userId,
    this.status = RegistrationStatus.pending,
    required this.fullName,
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
    this.vehicleId,
    this.vehicleSummary,
    this.createdAt,
    this.updatedAt,
    this.shareMedicalInfo = false,
    this.allowOrganizerContact = false,
    this.riskAcceptedAt,
    this.riskAcceptanceVersion,
  });

  String get registrationTitle => 'Inscripción al evento $eventName';

  EventRegistrationModel copyWith({
    String? id,
    String? eventId,
    String? eventName,
    String? userId,
    RegistrationStatus? status,
    String? fullName,
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
    String? vehicleId,
    VehicleSummaryModel? vehicleSummary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? shareMedicalInfo,
    bool? allowOrganizerContact,
    DateTime? riskAcceptedAt,
    String? riskAcceptanceVersion,
  }) {
    return EventRegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
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
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleSummary: vehicleSummary ?? this.vehicleSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shareMedicalInfo: shareMedicalInfo ?? this.shareMedicalInfo,
      allowOrganizerContact:
          allowOrganizerContact ?? this.allowOrganizerContact,
      riskAcceptedAt: riskAcceptedAt ?? this.riskAcceptedAt,
      riskAcceptanceVersion:
          riskAcceptanceVersion ?? this.riskAcceptanceVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventRegistrationModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
