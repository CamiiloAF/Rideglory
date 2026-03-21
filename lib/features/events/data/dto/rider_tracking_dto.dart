import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/events/data/dto/rider_tracking_dto_converters.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';

part 'rider_tracking_dto.g.dart';

@JsonSerializable(explicitToJson: true)
@RiderTrackingRoleConverter()
@TrackingFirestoreDateTimeConverter()
class RiderTrackingDto extends RiderTrackingModel {
  const RiderTrackingDto({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.role,
    required super.latitude,
    required super.longitude,
    required super.speedKmh,
    required super.distanceMeters,
    required super.batteryPercent,
    required super.isActive,
    required super.deviceLabel,
    required super.lastUpdated,
  });

  factory RiderTrackingDto.fromJson(Map<String, dynamic> json) =>
      _$RiderTrackingDtoFromJson(_normalizeTrackingJson(json));

  Map<String, dynamic> toJson() => _$RiderTrackingDtoToJson(this);

  factory RiderTrackingDto.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final json = Map<String, dynamic>.from(data);
    json['userId'] = json['userId'] as String? ?? documentId;
    return RiderTrackingDto.fromJson(json);
  }

  /// Ensures Firestore partial documents deserialize like the previous manual [fromFirestore].
  static Map<String, dynamic> _normalizeTrackingJson(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    m['firstName'] ??= '';
    m['lastName'] ??= '';
    m['latitude'] ??= 0;
    m['longitude'] ??= 0;
    m['speedKmh'] ??= 0;
    m['distanceMeters'] ??= 0;
    m['batteryPercent'] ??= -1;
    m['isActive'] ??= true;
    m['deviceLabel'] ??= '';
    return m;
  }
}

extension RiderTrackingModelExtension on RiderTrackingModel {
  Map<String, dynamic> toJson() => RiderTrackingDto(
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    role: role,
    latitude: latitude,
    longitude: longitude,
    speedKmh: speedKmh,
    distanceMeters: distanceMeters,
    batteryPercent: batteryPercent,
    isActive: isActive,
    deviceLabel: deviceLabel,
    lastUpdated: lastUpdated,
  ).toJson();
}
