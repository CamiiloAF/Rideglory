import 'package:firebase_auth/firebase_auth.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.firebaseUser,
    required this.isNewUser,
    this.user,
  });

  final User firebaseUser;
  final UserModel? user;
  final bool isNewUser;
}
