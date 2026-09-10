import 'package:json_annotation/json_annotation.dart';

import '../../domain/sos_alert.dart';
import '../../domain/sos_status.dart';

part 'sos_alert_dto.g.dart';

/// Fila de la vista `sos_alerts_visible` o de la fila devuelta por
/// `raise_sos`/`close_sos`.
@JsonSerializable()
class SosAlertDto {
  const SosAlertDto({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.riderName,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    this.riderPhone,
    this.accuracyM,
    this.message,
    this.closedAt,
    this.closedBy,
  });

  factory SosAlertDto.fromJson(Map<String, dynamic> json) =>
      _$SosAlertDtoFromJson(json);

  final String id;
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'rider_name')
  final String riderName;
  final double lat;
  final double lng;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'rider_phone')
  final String? riderPhone;
  @JsonKey(name: 'accuracy_m')
  final double? accuracyM;
  final String? message;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  @JsonKey(name: 'closed_by')
  final String? closedBy;

  SosAlert toDomain() => SosAlert(
    id: id,
    eventId: eventId,
    userId: userId,
    riderName: riderName,
    lat: lat,
    lng: lng,
    status: status == 'closed' ? SosStatus.closed : SosStatus.active,
    createdAt: createdAt,
    riderPhone: riderPhone,
    accuracyM: accuracyM,
    message: message,
    closedAt: closedAt,
    closedBy: closedBy,
  );
}
