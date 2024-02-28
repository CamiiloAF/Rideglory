import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../core/exceptions/failure.dart';
import '../../../domain/entities/user_model.dart';
import '../../../domain/repositories/users_repository_contract.dart';

part 'update_user_cubit.freezed.dart';

part 'update_user_state.dart';

class UpdateUserCubit extends Cubit<UpdateUserState> {
  UpdateUserCubit({required final UsersRepositoryContract usersRepository})
      : _usersRepository = usersRepository,
        super(const UpdateUserState.initial());

  final UsersRepositoryContract _usersRepository;

  Future<void> updateUser(final UserModel userModel) async {
    try {
      emit(const UpdatingUser());
      await _usersRepository.updateUser(userModel);
      emit(const UpdateUserSuccess());
    } on Failure catch (e) {
      emit(UpdateUserError(e.message));
    }
  }
}
