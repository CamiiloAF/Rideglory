import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.identificationNumber,
    this.birthDate,
    this.phone,
    this.residenceCity,
    this.eps,
    this.medicalInsurance,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.medicalConsentAcceptedAt,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? identificationNumber;
  final DateTime? birthDate;
  final String? phone;
  final String? residenceCity;
  final String? eps;
  final String? medicalInsurance;
  final BloodType? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? medicalConsentAcceptedAt;

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? identificationNumber,
    DateTime? birthDate,
    String? phone,
    String? residenceCity,
    String? eps,
    String? medicalInsurance,
    BloodType? bloodType,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? medicalConsentAcceptedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      residenceCity: residenceCity ?? this.residenceCity,
      eps: eps ?? this.eps,
      medicalInsurance: medicalInsurance ?? this.medicalInsurance,
      bloodType: bloodType ?? this.bloodType,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medicalConsentAcceptedAt:
          medicalConsentAcceptedAt ?? this.medicalConsentAcceptedAt,
    );
  }
}
