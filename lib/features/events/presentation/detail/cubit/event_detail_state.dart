part of 'event_detail_cubit.dart';

@freezed
abstract class EventDetailState with _$EventDetailState {
  const EventDetailState._();

  const factory EventDetailState({
    required ResultState<EventRegistrationModel?> registrationResult,
    required ResultState<EventModel> eventResult,
    /// Full list of registrations for this event (used by the participants
    /// section on event detail). Fetched from `/events/{id}/registrations`,
    /// not `/me` — `/me` only returns the current user's own row.
    @Default(ResultState<List<EventRegistrationModel>>.initial())
    ResultState<List<EventRegistrationModel>> attendeesResult,
    /// Set after a successful start/stop event mutation; cleared by the UI listener.
    ResultState<EventModel>? lastUpdatedEventResult,
  }) = _EventDetailState;
}
