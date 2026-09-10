import 'package:json_annotation/json_annotation.dart';

import '../../domain/live_ride_contacts.dart';

part 'live_ride_contacts_dto.g.dart';

/// Fila devuelta por la RPC `get_live_ride_contacts`.
@JsonSerializable()
class LiveRideContactsDto {
  const LiveRideContactsDto({
    required this.organizerName,
    this.organizerPhone,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory LiveRideContactsDto.fromJson(Map<String, dynamic> json) =>
      _$LiveRideContactsDtoFromJson(json);

  @JsonKey(name: 'organizer_name')
  final String organizerName;
  @JsonKey(name: 'organizer_phone')
  final String? organizerPhone;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  LiveRideContacts toDomain() => LiveRideContacts(
    organizerName: organizerName,
    organizerPhone: organizerPhone,
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
  );
}
