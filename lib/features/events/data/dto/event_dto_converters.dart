import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventDifficultyConverter extends JsonConverter<EventDifficulty, int> {
  const EventDifficultyConverter();

  @override
  EventDifficulty fromJson(int json) => EventDifficulty.fromValue(json);

  @override
  int toJson(EventDifficulty object) => object.value;
}

class EventStateConverter extends JsonConverter<EventState, String?> {
  const EventStateConverter();

  static const _map = {
    'scheduled': EventState.scheduled,
    'inProgress': EventState.inProgress,
    'cancelled': EventState.cancelled,
    'finished': EventState.finished,
  };

  @override
  EventState fromJson(String? json) {
    if (json == null) return EventState.scheduled;
    return _map[json] ?? EventState.scheduled;
  }

  @override
  String toJson(EventState object) {
    switch (object) {
      case EventState.scheduled:
        return 'scheduled';
      case EventState.inProgress:
        return 'inProgress';
      case EventState.cancelled:
        return 'cancelled';
      case EventState.finished:
        return 'finished';
    }
  }
}
