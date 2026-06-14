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
      'ON_ROAD' => EventType.onRoad,
      'OFF_ROAD' => EventType.offRoad,
      'COURSE' => EventType.course,
      'TRACK_DAY' => EventType.trackDay,
      'LEISURE' => EventType.leisure,
      'COMPETITION' => EventType.competition,
      // Compatibilidad con valores legacy del backend
      'TOURISM' => EventType.onRoad,
      'URBAN' => EventType.course,
      'SOLIDARITY' => EventType.leisure,
      'SHORT_DISTANCE' => EventType.leisure,
      _ => EventType.onRoad,
    };
  }

  @override
  String toJson(EventType object) {
    return switch (object) {
      EventType.onRoad => 'ON_ROAD',
      EventType.offRoad => 'OFF_ROAD',
      EventType.course => 'COURSE',
      EventType.trackDay => 'TRACK_DAY',
      EventType.leisure => 'LEISURE',
      EventType.competition => 'COMPETITION',
    };
  }
}

class EventStateConverter extends JsonConverter<EventState, String?> {
  const EventStateConverter();

  static const _map = {
    'draft': EventState.draft,
    'DRAFT': EventState.draft,
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
    return switch (object) {
      EventState.draft => 'DRAFT',
      EventState.scheduled => 'SCHEDULED',
      EventState.inProgress => 'IN_PROGRESS',
      EventState.cancelled => 'CANCELLED',
      EventState.finished => 'FINISHED',
    };
  }
}
