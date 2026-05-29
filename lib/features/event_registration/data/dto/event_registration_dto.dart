import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/data/dto/vehicle_summary_dto.dart';
import 'package:rideglory/features/event_registration/domain/model/vehicle_summary_model.dart';

part 'event_registration_dto.g.dart';

class _VehicleSummaryConverter
    implements JsonConverter<VehicleSummaryModel?, Map<String, dynamic>?> {
  const _VehicleSummaryConverter();

  @override
  VehicleSummaryModel? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : VehicleSummaryDto.fromJson(json);

  @override
  Map<String, dynamic>? toJson(VehicleSummaryModel? model) => model?.toJson();
}

@JsonSerializable(converters: apiJsonDateTimeConverters)
@_VehicleSummaryConverter()
class EventRegistrationDto extends EventRegistrationModel {
  const EventRegistrationDto({
    super.id,
    required super.eventId,
    super.eventName = '',
    required super.userId,
    super.status = RegistrationStatus.pending,
    required super.fullName,
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
    super.vehicleId,
    super.vehicleSummary,
    super.createdAt,
    super.updatedAt,
  });

  factory EventRegistrationDto.fromJson(Map<String, dynamic> json) =>
      _$EventRegistrationDtoFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$EventRegistrationDtoToJson(this);
    json['birthDate'] = apiEncodeRequiredDateTime(birthDate);
    return json;
  }
}

extension EventRegistrationModelExtension on EventRegistrationModel {
  Map<String, dynamic> toJson() => EventRegistrationDto(
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
  ).toJson();
}
