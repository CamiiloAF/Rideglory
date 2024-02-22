import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/users/domain/entities/user_model.dart';
import 'package:rideglory/features/users/domain/repositories/users_repository_contract.dart';

class CurrentUserCubit extends Cubit<UserModel?> {
  CurrentUserCubit({required UsersRepositoryContract usersRepository})
      : _usersRepository = usersRepository,
        super(null);

  final UsersRepositoryContract _usersRepository;

  UserModel? _userModel;

  Future<UserModel> getCurrentUser() async {
    try {
      _userModel = _userModel ?? await _usersRepository.getCurrentUser();
      emit(_userModel);
      return _userModel!;
    } catch (e) {
      rethrow;
    }
  }
}
