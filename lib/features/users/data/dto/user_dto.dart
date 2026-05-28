import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

part 'user_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
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

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

extension UserModelExtension on UserModel {
  Map<String, dynamic> toJson() => UserDto(
    id: id,
    fullName: fullName,
    email: email,
    identificationNumber: identificationNumber,
    birthDate: birthDate,
    phone: phone,
    residenceCity: residenceCity,
    eps: eps,
    medicalInsurance: medicalInsurance,
    bloodType: bloodType,
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
    isDeleted: isDeleted,
    createdAt: createdAt,
    updatedAt: updatedAt,
  ).toJson();
}
