part of 'event_detail_cubit.dart';

@freezed
abstract class EventDetailState with _$EventDetailState {
  const EventDetailState._();

  const factory EventDetailState({
    required ResultState<EventRegistrationModel?> registrationResult,
    required ResultState<EventModel> eventResult,
  }) = _EventDetailState;
}
