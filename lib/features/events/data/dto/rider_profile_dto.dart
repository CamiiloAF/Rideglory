import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';

part 'rider_profile_dto.g.dart';

@JsonSerializable()
class RiderProfileDto extends RiderProfileModel {
  const RiderProfileDto({
    required super.id,
    required super.userId,
    super.firstName,
    super.lastName,
    super.identificationNumber,
    super.birthDate,
    super.phone,
    super.email,
    super.residenceCity,
    super.eps,
    super.medicalInsurance,
    super.bloodType,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.updatedDate,
  });

  factory RiderProfileDto.fromJson(Map<String, dynamic> json) =>
      _$RiderProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RiderProfileDtoToJson(this);
}

extension RiderProfileModelExtension on RiderProfileModel {
  Map<String, dynamic> toJson() => RiderProfileDto(
    id: id,
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    identificationNumber: identificationNumber,
    birthDate: birthDate,
    phone: phone,
    email: email,
    residenceCity: residenceCity,
    eps: eps,
    medicalInsurance: medicalInsurance,
    bloodType: bloodType,
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
    updatedDate: updatedDate,
  ).toJson();
}
