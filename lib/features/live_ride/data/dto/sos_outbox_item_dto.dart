import '../../domain/rider_position.dart';
import '../../domain/sos_outbox_item.dart';

/// JSON manual (sin codegen) de [SosOutboxItem] para la cola durable de
/// `SharedPreferencesSosOutbox`. Manual porque es un formato de
/// persistencia interno, no un contrato de red — no vale la pena un DTO
/// generado para un solo archivo que solo se lee a sí mismo.
class SosOutboxItemDto {
  const SosOutboxItemDto(this.item);

  final SosOutboxItem item;

  static SosOutboxItem fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>;
    return SosOutboxItem(
      clientId: json['clientId'] as String,
      eventId: json['eventId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      message: json['message'] as String?,
      attempts: json['attempts'] as int? ?? 0,
      position: RiderPosition(
        lat: (position['lat'] as num).toDouble(),
        lng: (position['lng'] as num).toDouble(),
        recordedAt: DateTime.parse(position['recordedAt'] as String),
        speedKmh: (position['speedKmh'] as num?)?.toDouble(),
        heading: (position['heading'] as num?)?.toDouble(),
        accuracyM: (position['accuracyM'] as num?)?.toDouble(),
        batteryPct: position['batteryPct'] as int?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'clientId': item.clientId,
    'eventId': item.eventId,
    'createdAt': item.createdAt.toIso8601String(),
    'message': item.message,
    'attempts': item.attempts,
    'position': {
      'lat': item.position.lat,
      'lng': item.position.lng,
      'recordedAt': item.position.recordedAt.toIso8601String(),
      'speedKmh': item.position.speedKmh,
      'heading': item.position.heading,
      'accuracyM': item.position.accuracyM,
      'batteryPct': item.position.batteryPct,
    },
  };
}
