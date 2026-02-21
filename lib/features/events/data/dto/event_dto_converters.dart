import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventDifficultyConverter extends JsonConverter<EventDifficulty, int> {
  const EventDifficultyConverter();

  @override
  EventDifficulty fromJson(int json) => EventDifficulty.fromValue(json);

  @override
  int toJson(EventDifficulty object) => object.value;
}
