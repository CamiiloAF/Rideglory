part of 'event_detail_cubit.dart';

@freezed
abstract class EventDetailState with _$EventDetailState {
  const EventDetailState._();

  const factory EventDetailState({
    required ResultState<EventRegistrationModel?> registrationResult,
    required ResultState<EventModel> eventResult,
    /// Set after a successful start/stop event mutation; cleared by the UI listener.
    ResultState<EventModel>? lastUpdatedEventResult,
  }) = _EventDetailState;
}
