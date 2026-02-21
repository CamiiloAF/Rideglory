part of 'event_form_cubit.dart';

@freezed
class EventFormState with _$EventFormState {
  const factory EventFormState.initial() = _Initial;
  const factory EventFormState.editing({required EventModel event}) = _Editing;
  const factory EventFormState.loading() = _Loading;
  const factory EventFormState.success({required EventModel event}) = _Success;
  const factory EventFormState.error({required String message}) = _Error;
}
