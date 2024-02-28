part of 'update_user_cubit.dart';

@freezed
class UpdateUserState with _$UpdateUserState {
  const factory UpdateUserState.initial() = _Initial;

  const factory UpdateUserState.updating() = UpdatingUser;

  const factory UpdateUserState.success() = UpdateUserSuccess;

  const factory UpdateUserState.error(final String message) = UpdateUserError;
}
