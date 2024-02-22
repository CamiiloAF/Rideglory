part of 'sign_up_cubit.dart';

@freezed
class SignUpState with _$SignUpState {
  const factory SignUpState.initial() = _Initial;

  const factory SignUpState.loading() = LoadingSignUp;

  const factory SignUpState.success() = SignUpSuccess;

  const factory SignUpState.error(final String message) = SignUpError;
}
