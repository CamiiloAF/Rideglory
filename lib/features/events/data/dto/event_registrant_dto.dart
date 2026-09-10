import 'package:json_annotation/json_annotation.dart';

import '../../domain/event_registrant.dart';
import '../../domain/registration_status.dart';

part 'event_registrant_dto.g.dart';

/// DTO de una fila de `event_registrations_for_organizer`. Los campos
/// enmascarados ya vienen `null` desde la vista cuando el rider no dio el
/// opt-in correspondiente.
@JsonSerializable()
class EventRegistrantDto {
  const EventRegistrantDto({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.status,
    required this.shareMedicalInfo,
    required this.allowOrganizerContact,
    this.vehicleName,
    this.vehicleBrand,
    this.vehicleModel,
    this.phone,
    this.bloodType,
    this.eps,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory EventRegistrantDto.fromJson(Map<String, dynamic> json) =>
      _$EventRegistrantDtoFromJson(json);

  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String status;
  @JsonKey(name: 'share_medical_info')
  final bool shareMedicalInfo;
  @JsonKey(name: 'allow_organizer_contact')
  final bool allowOrganizerContact;
  @JsonKey(name: 'vehicle_name')
  final String? vehicleName;
  @JsonKey(name: 'vehicle_brand')
  final String? vehicleBrand;
  @JsonKey(name: 'vehicle_model')
  final String? vehicleModel;
  final String? phone;
  @JsonKey(name: 'blood_type')
  final String? bloodType;
  final String? eps;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  EventRegistrant toDomain() {
    final model = vehicleModel?.trim();
    final vehicleDisplayName = vehicleBrand == null
        ? null
        : (model != null && model.isNotEmpty)
        ? '$vehicleBrand $model'
        : vehicleName;
    return EventRegistrant(
      id: id,
      userId: userId,
      fullName: fullName,
      status: _statusFrom(status),
      shareMedicalInfo: shareMedicalInfo,
      allowOrganizerContact: allowOrganizerContact,
      vehicleName: vehicleDisplayName,
      phone: phone,
      bloodType: bloodType == null ? null : _bloodTypeFrom(bloodType!),
      eps: eps,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );
  }
}

RegistrationStatus _statusFrom(String value) => switch (value) {
  'pending' => RegistrationStatus.pending,
  'approved' => RegistrationStatus.approved,
  'rejected' => RegistrationStatus.rejected,
  'cancelled' => RegistrationStatus.cancelled,
  _ => throw ArgumentError('unknown_registration_status: $value'),
};

EventBloodType _bloodTypeFrom(String value) => switch (value) {
  'o_positive' => EventBloodType.oPositive,
  'o_negative' => EventBloodType.oNegative,
  'a_positive' => EventBloodType.aPositive,
  'a_negative' => EventBloodType.aNegative,
  'b_positive' => EventBloodType.bPositive,
  'b_negative' => EventBloodType.bNegative,
  'ab_positive' => EventBloodType.abPositive,
  'ab_negative' => EventBloodType.abNegative,
  _ => throw ArgumentError('unknown_blood_type: $value'),
};
