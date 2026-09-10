import 'package:freezed_annotation/freezed_annotation.dart';

part 'rider_position.freezed.dart';

/// Una lectura de posición del dispositivo, lista para publicarse con
/// `upsert_live_position` o para viajar dentro de un [SosOutboxItem].
/// `batteryPct` se completa aparte (servicio de batería), no lo conoce el
/// GPS.
@freezed
abstract class RiderPosition with _$RiderPosition {
  const factory RiderPosition({
    required double lat,
    required double lng,
    required DateTime recordedAt,
    double? speedKmh,
    double? heading,
    double? accuracyM,
    int? batteryPct,
  }) = _RiderPosition;
}
