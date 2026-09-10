import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_rider.freezed.dart';

/// Una fila de la vista `live_riders`: la última posición conocida de un
/// participante de una rodada en curso.
@freezed
abstract class LiveRider with _$LiveRider {
  const factory LiveRider({
    required String eventId,
    required String userId,
    required String fullName,
    required bool isOrganizer,
    required double lat,
    required double lng,
    required DateTime recordedAt,
    required DateTime updatedAt,
    double? speedKmh,
    double? heading,
    int? batteryPct,
    double? accuracyM,
  }) = _LiveRider;
}
