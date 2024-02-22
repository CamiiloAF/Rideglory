import '../../../../../core/models/user_model.dart';

abstract class SignUpRepositoryContract {
  Future<void> signUp(UserModel userModel);
}
