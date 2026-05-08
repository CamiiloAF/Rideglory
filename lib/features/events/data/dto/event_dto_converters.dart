import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventDifficultyConverter extends JsonConverter<EventDifficulty, Object> {
  const EventDifficultyConverter();

  @override
  EventDifficulty fromJson(Object json) {
    if (json is int) {
      return EventDifficulty.fromValue(json);
    }

    return switch (json) {
      'EASY' => EventDifficulty.one,
      'MODERATE' => EventDifficulty.two,
      'MEDIUM' => EventDifficulty.three,
      'HARD' => EventDifficulty.four,
      'VERY_HARD' => EventDifficulty.five,
      _ => EventDifficulty.one,
    };
  }

  @override
  Object toJson(EventDifficulty object) {
    return switch (object) {
      EventDifficulty.one => 'EASY',
      EventDifficulty.two => 'MODERATE',
      EventDifficulty.three => 'MEDIUM',
      EventDifficulty.four => 'HARD',
      EventDifficulty.five => 'VERY_HARD',
    };
  }
}

class EventTypeConverter extends JsonConverter<EventType, String> {
  const EventTypeConverter();

  @override
  EventType fromJson(String json) {
    return switch (json) {
      'OFF_ROAD' || 'offRoad' => EventType.offRoad,
      'ON_ROAD' || 'onRoad' => EventType.onRoad,
      'EXHIBITION' || 'exhibition' => EventType.exhibition,
      'CHARITABLE' || 'charitable' => EventType.charitable,
      _ => EventType.onRoad,
    };
  }

  @override
  String toJson(EventType object) {
    return switch (object) {
      EventType.offRoad => 'OFF_ROAD',
      EventType.onRoad => 'ON_ROAD',
      EventType.exhibition => 'EXHIBITION',
      EventType.charitable => 'CHARITABLE',
    };
  }
}

class EventStateConverter extends JsonConverter<EventState, String?> {
  const EventStateConverter();

  static const _map = {
    'scheduled': EventState.scheduled,
    'inProgress': EventState.inProgress,
    'cancelled': EventState.cancelled,
    'finished': EventState.finished,
    'SCHEDULED': EventState.scheduled,
    'IN_PROGRESS': EventState.inProgress,
    'CANCELLED': EventState.cancelled,
    'FINISHED': EventState.finished,
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
        return 'SCHEDULED';
      case EventState.inProgress:
        return 'IN_PROGRESS';
      case EventState.cancelled:
        return 'CANCELLED';
      case EventState.finished:
        return 'FINISHED';
    }
  }
}
