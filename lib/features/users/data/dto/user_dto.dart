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

  factory UserDto.fromModel(UserModel model) => UserDto(
    id: model.id,
    fullName: model.fullName,
    email: model.email,
    identificationNumber: model.identificationNumber,
    birthDate: model.birthDate,
    phone: model.phone,
    residenceCity: model.residenceCity,
    eps: model.eps,
    medicalInsurance: model.medicalInsurance,
    bloodType: model.bloodType,
    emergencyContactName: model.emergencyContactName,
    emergencyContactPhone: model.emergencyContactPhone,
    isDeleted: model.isDeleted,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
  );

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}
