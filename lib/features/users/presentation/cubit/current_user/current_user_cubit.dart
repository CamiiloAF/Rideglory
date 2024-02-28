import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user_model.dart';
import '../../../domain/repositories/users_repository_contract.dart';

class CurrentUserCubit extends Cubit<UserModel?> {
  CurrentUserCubit({required final UsersRepositoryContract usersRepository})
      : _usersRepository = usersRepository,
        super(null);

  final UsersRepositoryContract _usersRepository;

  UserModel? _userModel;

  UserModel? get userModel => _userModel;

  Future<UserModel> fetchCurrentUser() async {
    try {
      _userModel = _userModel ?? await _usersRepository.getCurrentUser();
      emit(_userModel);
      return _userModel!;
    } catch (e) {
      rethrow;
    }
  }
}
