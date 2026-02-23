import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';

part 'event_registration_dto.g.dart';

@JsonSerializable()
class EventRegistrationDto extends EventRegistrationModel {
  @JsonKey(defaultValue: '')
  @override
  final String eventName;

  const EventRegistrationDto({
    required super.id,
    required super.eventId,
    required this.eventName,
    required super.userId,
    required super.status,
    required super.firstName,
    required super.lastName,
    required super.identificationNumber,
    required super.birthDate,
    required super.phone,
    required super.email,
    required super.residenceCity,
    required super.eps,
    super.medicalInsurance,
    required super.bloodType,
    required super.emergencyContactName,
    required super.emergencyContactPhone,
    required super.vehicleBrand,
    required super.vehicleReference,
    required super.licensePlate,
    super.vin,
    super.createdDate,
    super.updatedDate,
  }) : super(eventName: eventName);

  factory EventRegistrationDto.fromJson(Map<String, dynamic> json) =>
      _$EventRegistrationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventRegistrationDtoToJson(this);
}

extension EventRegistrationModelExtension on EventRegistrationModel {
  Map<String, dynamic> toJson() => EventRegistrationDto(
    id: id,
    eventId: eventId,
    eventName: eventName,
    userId: userId,
    status: status,
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
    vehicleBrand: vehicleBrand,
    vehicleReference: vehicleReference,
    licensePlate: licensePlate,
    vin: vin,
    createdDate: createdDate,
    updatedDate: updatedDate,
  ).toJson();
}
