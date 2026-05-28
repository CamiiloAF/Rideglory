import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/events/data/dto/event_dto_converters.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

part 'event_dto.g.dart';

@JsonSerializable(explicitToJson: true, converters: apiJsonDateTimeConverters)
@EventDifficultyConverter()
@EventTypeConverter()
@EventStateConverter()
class EventDto extends EventModel {
  const EventDto({
    required super.id,
    required super.ownerId,
    super.ownerName,
    required super.name,
    required super.description,
    required super.city,
    required super.startDate,
    super.endDate,
    required super.difficulty,
    required super.meetingPoint,
    required super.destination,
    required super.meetingTime,
    required super.eventType,
    super.allowedBrands = const [],
    super.price,
    @JsonKey(name: 'maxParticipants') super.maxParticipants,
    super.imageUrl,
    @JsonKey(name: 'createdAt') super.createdDate,
    @JsonKey(name: 'updatedAt') super.updatedDate,
    super.state = EventState.scheduled,
    super.waypoints = const [],
    @JsonKey(name: 'routeGeoJson') super.routeGeoJson,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$EventDtoToJson(this);
    json['startDate'] = apiEncodeRequiredDateTime(startDate);
    json['meetingTime'] = apiEncodeRequiredDateTime(meetingTime);
    return json;
  }
}

extension EventModelExtension on EventModel {
  Map<String, dynamic> toJson() => EventDto(
    id: id,
    ownerId: ownerId,
    name: name,
    description: description,
    city: city,
    startDate: startDate,
    endDate: endDate,
    difficulty: difficulty,
    meetingPoint: meetingPoint,
    destination: destination,
    meetingTime: meetingTime,
    eventType: eventType,
    allowedBrands: allowedBrands,
    price: price,
    maxParticipants: maxParticipants,
    imageUrl: imageUrl,
    createdDate: createdDate,
    updatedDate: updatedDate,
    state: state,
    waypoints: waypoints,
    routeGeoJson: routeGeoJson,
  ).toJson();
}
