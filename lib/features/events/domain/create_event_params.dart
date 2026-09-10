import 'package:freezed_annotation/freezed_annotation.dart';

import 'event_difficulty.dart';

part 'create_event_params.freezed.dart';

/// Datos del asistente de creación en 3 pasos (EV3), reunidos para
/// publicar en un solo llamado.
@freezed
abstract class CreateEventParams with _$CreateEventParams {
  const factory CreateEventParams({
    required String name,
    required DateTime startAt,
    required String meetingPoint,
    required String destinationName,
    required double destinationLat,
    required double destinationLng,
    required String routeText,
    required EventDifficulty difficulty,
    required int maxParticipants,
    required int price,
    String? description,
    String? localImagePath,
  }) = _CreateEventParams;
}
