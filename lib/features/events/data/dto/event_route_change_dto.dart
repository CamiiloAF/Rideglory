import 'package:json_annotation/json_annotation.dart';

import '../../domain/event_route_change.dart';

part 'event_route_change_dto.g.dart';

@JsonSerializable()
class EventRouteChangeDto {
  const EventRouteChangeDto({
    required this.id,
    required this.eventId,
    required this.message,
    required this.createdAt,
  });

  factory EventRouteChangeDto.fromJson(Map<String, dynamic> json) =>
      _$EventRouteChangeDtoFromJson(json);

  final String id;
  @JsonKey(name: 'event_id')
  final String eventId;
  final String message;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  EventRouteChange toDomain() => EventRouteChange(
    id: id,
    eventId: eventId,
    message: message,
    createdAt: createdAt,
  );
}
