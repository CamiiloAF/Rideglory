part of 'registration_form_cubit.dart';

@freezed
class RegistrationFormState with _$RegistrationFormState {
  const factory RegistrationFormState.initial() = _Initial;
  const factory RegistrationFormState.editing({
    required EventRegistrationModel registration,
  }) = _Editing;
  const factory RegistrationFormState.loading() = _Loading;
  const factory RegistrationFormState.success({
    required EventRegistrationModel registration,
  }) = _Success;
  const factory RegistrationFormState.error({required String message}) = _Error;
}
