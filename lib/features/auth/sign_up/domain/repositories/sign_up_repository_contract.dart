
import '../../../../users/domain/entities/user_model.dart';

abstract interface class SignUpRepositoryContract {
  Future<void> signUp(final UserModel userModel);
}
