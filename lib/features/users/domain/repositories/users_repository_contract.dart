import '../entities/user_model.dart';

abstract interface class UsersRepositoryContract {
  Future<UserModel> getCurrentUser();

  Future<void> updateUser(UserModel userModel);
}
