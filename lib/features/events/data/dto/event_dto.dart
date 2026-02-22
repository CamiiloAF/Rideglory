import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/events/data/dto/event_dto_converters.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

part 'event_dto.g.dart';

@JsonSerializable(explicitToJson: true)
@EventDifficultyConverter()
class EventDto extends EventModel {
  const EventDto({
    required super.id,
    required super.ownerId,
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
    super.recommendations,
    super.createdDate,
    super.updatedDate,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventDtoToJson(this);
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
    recommendations: recommendations,
    createdDate: createdDate,
    updatedDate: updatedDate,
  ).toJson();
}
