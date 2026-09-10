import 'package:json_annotation/json_annotation.dart';

import '../../domain/event.dart';
import '../../domain/event_difficulty.dart';
import '../../domain/event_state.dart';
import '../../domain/registration_status.dart';

part 'event_dto.g.dart';

/// DTO de una fila de la vista `events_public`. `myRegistrationStatus` no
/// viene de la vista: se completa aparte (ver datasource) porque la vista
/// no conoce el rider que consulta.
@JsonSerializable()
class EventDto {
  const EventDto({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.startAt,
    required this.difficulty,
    required this.price,
    required this.state,
    required this.approvedCount,
    this.description,
    this.routeText,
    this.meetingPoint,
    this.destinationName,
    this.destinationLat,
    this.destinationLng,
    this.imagePath,
    this.maxParticipants,
    this.startedAt,
    this.myRegistrationStatus,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  final String id;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'owner_name')
  final String ownerName;
  final String name;
  @JsonKey(name: 'start_at')
  final DateTime startAt;
  final int difficulty;
  final int price;
  final String state;
  @JsonKey(name: 'approved_count')
  final int approvedCount;
  final String? description;
  @JsonKey(name: 'route_text')
  final String? routeText;
  @JsonKey(name: 'meeting_point')
  final String? meetingPoint;
  @JsonKey(name: 'destination_name')
  final String? destinationName;
  @JsonKey(name: 'destination_lat')
  final double? destinationLat;
  @JsonKey(name: 'destination_lng')
  final double? destinationLng;
  @JsonKey(name: 'image_path')
  final String? imagePath;
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? myRegistrationStatus;

  Event toDomain({required String currentUserId, String? imageUrl}) {
    return Event(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      name: name,
      startAt: startAt,
      difficulty: eventDifficultyFromScore(difficulty),
      state: _stateFrom(state),
      price: price,
      approvedCount: approvedCount,
      description: description,
      routeText: routeText,
      meetingPoint: meetingPoint,
      destinationName: destinationName,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      imageUrl: imageUrl,
      maxParticipants: maxParticipants,
      startedAt: startedAt,
      myRegistrationStatus: myRegistrationStatus == null
          ? null
          : _registrationStatusFrom(myRegistrationStatus!),
      isOwnedByMe: ownerId == currentUserId,
    );
  }

  EventDto copyWithRegistrationStatus(String? status) {
    return EventDto(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      name: name,
      startAt: startAt,
      difficulty: difficulty,
      price: price,
      state: state,
      approvedCount: approvedCount,
      description: description,
      routeText: routeText,
      meetingPoint: meetingPoint,
      destinationName: destinationName,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      imagePath: imagePath,
      maxParticipants: maxParticipants,
      startedAt: startedAt,
      myRegistrationStatus: status,
    );
  }
}

EventState _stateFrom(String value) => switch (value) {
  'draft' => EventState.draft,
  'published' => EventState.published,
  'started' => EventState.started,
  'finished' => EventState.finished,
  'cancelled' => EventState.cancelled,
  _ => throw ArgumentError('unknown_event_state: $value'),
};

RegistrationStatus _registrationStatusFrom(String value) => switch (value) {
  'pending' => RegistrationStatus.pending,
  'approved' => RegistrationStatus.approved,
  'rejected' => RegistrationStatus.rejected,
  'cancelled' => RegistrationStatus.cancelled,
  _ => throw ArgumentError('unknown_registration_status: $value'),
};
