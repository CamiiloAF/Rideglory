import 'package:rideglory/features/events/domain/model/event_registration_model.dart';

class RiderProfileModel {
  final String? id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? identificationNumber;
  final DateTime? birthDate;
  final String? phone;
  final String? email;
  final String? residenceCity;
  final String? eps;
  final String? medicalInsurance;
  final BloodType? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? updatedDate;

  const RiderProfileModel({
    this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.identificationNumber,
    this.birthDate,
    this.phone,
    this.email,
    this.residenceCity,
    this.eps,
    this.medicalInsurance,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.updatedDate,
  });

  RiderProfileModel copyWith({
    String? id,
    String? userId,
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
    DateTime? updatedDate,
  }) {
    return RiderProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}
