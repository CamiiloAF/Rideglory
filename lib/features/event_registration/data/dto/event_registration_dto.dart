import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/data/dto/vehicle_summary_dto.dart';

part 'event_registration_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class EventRegistrationDto {
  const EventRegistrationDto({
    this.id,
    required this.eventId,
    this.eventName = '',
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
  });

  final String? id;
  final String eventId;
  @JsonKey(defaultValue: '')
  final String eventName;
  final String userId;
  final RegistrationStatus status;

  final String fullName;
  final String identificationNumber;
  final DateTime birthDate;
  final String phone;
  final String email;
  final String residenceCity;

  final String eps;
  final String? medicalInsurance;
  final BloodType bloodType;

  final String emergencyContactName;
  final String emergencyContactPhone;

  final String? vehicleId;
  final VehicleSummaryDto? vehicleSummary;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EventRegistrationDto.fromJson(Map<String, dynamic> json) =>
      _$EventRegistrationDtoFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$EventRegistrationDtoToJson(this);
    json['birthDate'] = apiEncodeRequiredDateTime(birthDate);
    return json;
  }

  EventRegistrationModel toModel() => EventRegistrationModel(
    id: id,
    eventId: eventId,
    eventName: eventName,
    userId: userId,
    status: status,
    fullName: fullName,
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
    vehicleId: vehicleId,
    vehicleSummary: vehicleSummary?.toModel(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension EventRegistrationModelToDto on EventRegistrationModel {
  EventRegistrationDto toDto() => EventRegistrationDto(
    id: id,
    eventId: eventId,
    eventName: eventName,
    userId: userId,
    status: status,
    fullName: fullName,
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
    vehicleId: vehicleId,
    vehicleSummary: vehicleSummary == null
        ? null
        : VehicleSummaryDto(
            id: vehicleSummary!.id,
            brand: vehicleSummary!.brand,
            model: vehicleSummary!.model,
            licensePlate: vehicleSummary!.licensePlate,
            vin: vehicleSummary!.vin,
          ),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
