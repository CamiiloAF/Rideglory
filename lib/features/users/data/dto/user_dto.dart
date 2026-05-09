import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class UserDto extends UserModel {
  const UserDto({
    required super.id,
    required super.fullName,
    required super.email,
    super.identificationNumber,
    super.birthDate,
    super.phone,
    super.residenceCity,
    super.eps,
    super.medicalInsurance,
    super.bloodType,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.isDeleted,
    super.createdAt,
    super.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      identificationNumber: json['identificationNumber'] as String?,
      birthDate: _dateTimeFromJson(json['birthDate']),
      phone: json['phone'] as String?,
      residenceCity: json['residenceCity'] as String?,
      eps: json['eps'] as String?,
      medicalInsurance: json['medicalInsurance'] as String?,
      bloodType: json['bloodType'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'identificationNumber': identificationNumber,
      'birthDate': birthDate?.toApiIso8601String(),
      'phone': phone,
      'residenceCity': residenceCity,
      'eps': eps,
      'medicalInsurance': medicalInsurance,
      'bloodType': bloodType,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toApiIso8601String(),
      'updatedAt': updatedAt?.toApiIso8601String(),
    };
  }
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
