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

class _BloodTypeConverter implements JsonConverter<BloodType?, String?> {
  const _BloodTypeConverter();

  @override
  BloodType? fromJson(String? json) {
    if (json == null) return null;
    for (final value in BloodType.values) {
      // Match the exact @JsonValue string, never a derived/uppercased name.
      if (_jsonValueOf(value) == json) return value;
    }
    return null;
  }

  @override
  String? toJson(BloodType? value) =>
      value == null ? null : _jsonValueOf(value);

  static String _jsonValueOf(BloodType value) => switch (value) {
    BloodType.aPositive => 'A_POSITIVE',
    BloodType.aNegative => 'A_NEGATIVE',
    BloodType.bPositive => 'B_POSITIVE',
    BloodType.bNegative => 'B_NEGATIVE',
    BloodType.abPositive => 'AB_POSITIVE',
    BloodType.abNegative => 'AB_NEGATIVE',
    BloodType.oPositive => 'O_POSITIVE',
    BloodType.oNegative => 'O_NEGATIVE',
  };
}

@JsonSerializable(converters: apiJsonDateTimeConverters)
@_VehicleSummaryConverter()
@_BloodTypeConverter()
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
    @JsonKey(includeFromJson: false, includeToJson: false) super.bloodTypeRaw,
    required super.emergencyContactName,
    required super.emergencyContactPhone,
    super.vehicleId,
    super.vehicleSummary,
    super.createdAt,
    super.updatedAt,
    super.shareMedicalInfo,
    super.allowOrganizerContact,
    super.riskAcceptedAt,
    super.riskAcceptanceVersion,
    super.medicalConsentAcceptedAt,
    super.medicalConsentVersion,
  });

  factory EventRegistrationDto.fromJson(Map<String, dynamic> json) {
    final generated = _$EventRegistrationDtoFromJson(json);
    final rawBloodType = json['bloodType'] as String?;
    final bloodTypeRaw =
        generated.bloodType == null &&
            rawBloodType != null &&
            rawBloodType.isNotEmpty
        ? rawBloodType
        : null;
    if (bloodTypeRaw == null) return generated;
    return EventRegistrationDto(
      id: generated.id,
      eventId: generated.eventId,
      eventName: generated.eventName,
      userId: generated.userId,
      status: generated.status,
      fullName: generated.fullName,
      identificationNumber: generated.identificationNumber,
      birthDate: generated.birthDate,
      phone: generated.phone,
      email: generated.email,
      residenceCity: generated.residenceCity,
      eps: generated.eps,
      medicalInsurance: generated.medicalInsurance,
      bloodType: generated.bloodType,
      bloodTypeRaw: bloodTypeRaw,
      emergencyContactName: generated.emergencyContactName,
      emergencyContactPhone: generated.emergencyContactPhone,
      vehicleId: generated.vehicleId,
      vehicleSummary: generated.vehicleSummary,
      createdAt: generated.createdAt,
      updatedAt: generated.updatedAt,
      shareMedicalInfo: generated.shareMedicalInfo,
      allowOrganizerContact: generated.allowOrganizerContact,
      riskAcceptedAt: generated.riskAcceptedAt,
      riskAcceptanceVersion: generated.riskAcceptanceVersion,
      medicalConsentAcceptedAt: generated.medicalConsentAcceptedAt,
      medicalConsentVersion: generated.medicalConsentVersion,
    );
  }

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
    bloodTypeRaw: bloodTypeRaw,
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
    shareMedicalInfo: shareMedicalInfo,
    allowOrganizerContact: allowOrganizerContact,
    riskAcceptedAt: riskAcceptedAt,
    riskAcceptanceVersion: riskAcceptanceVersion,
    medicalConsentAcceptedAt: medicalConsentAcceptedAt,
    medicalConsentVersion: medicalConsentVersion,
  ).toJson();
}
