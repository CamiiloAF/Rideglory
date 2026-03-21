import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';

class RiderTrackingRoleConverter extends JsonConverter<RiderTrackingRole, String?> {
  const RiderTrackingRoleConverter();

  @override
  RiderTrackingRole fromJson(String? json) => RiderTrackingRole.fromStorage(json);

  @override
  String toJson(RiderTrackingRole object) => object.name;
}

class TrackingFirestoreDateTimeConverter extends JsonConverter<DateTime, Object?> {
  const TrackingFirestoreDateTimeConverter();

  @override
  DateTime fromJson(Object? json) {
    if (json == null) {
      return DateTime.now();
    }
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is DateTime) {
      return json;
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return DateTime.now();
  }

  @override
  Object toJson(DateTime object) => Timestamp.fromDate(object);
}
