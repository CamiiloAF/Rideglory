import 'package:json_annotation/json_annotation.dart';

import '../../domain/live_rider.dart';

part 'live_rider_dto.g.dart';

/// Fila de la vista `live_riders`.
@JsonSerializable()
class LiveRiderDto {
  const LiveRiderDto({
    required this.eventId,
    required this.userId,
    required this.fullName,
    required this.isOrganizer,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    required this.updatedAt,
    this.speedKmh,
    this.heading,
    this.batteryPct,
    this.accuracyM,
  });

  factory LiveRiderDto.fromJson(Map<String, dynamic> json) =>
      _$LiveRiderDtoFromJson(json);

  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'is_organizer')
  final bool isOrganizer;
  final double lat;
  final double lng;
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'speed_kmh')
  final double? speedKmh;
  final double? heading;
  @JsonKey(name: 'battery_pct')
  final int? batteryPct;
  @JsonKey(name: 'accuracy_m')
  final double? accuracyM;

  LiveRider toDomain() => LiveRider(
    eventId: eventId,
    userId: userId,
    fullName: fullName,
    isOrganizer: isOrganizer,
    lat: lat,
    lng: lng,
    recordedAt: recordedAt,
    updatedAt: updatedAt,
    speedKmh: speedKmh,
    heading: heading,
    batteryPct: batteryPct,
    accuracyM: accuracyM,
  );
}
