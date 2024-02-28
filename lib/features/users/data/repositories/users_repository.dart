import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/exceptions/failure.dart';

import '../../domain/entities/user_model.dart';
import '../../domain/repositories/users_repository_contract.dart';

class UsersRepository implements UsersRepositoryContract {
  UsersRepository({
    required this.userCollectionReference,
    required this.auth,
  });

  final CollectionReference userCollectionReference;
  final FirebaseAuth auth;

  @override
  Future<UserModel> getCurrentUser() async {
    final user = auth.currentUser;
    if (user == null) {
      throw Failure('No user is currently signed in');
    }

    final doc = await userCollectionReference.doc(user.uid).get();

    if (!doc.exists) {
      throw Failure('No user data found for the current user');
    }

    return doc.data() as UserModel;
  }

  @override
  Future<void> updateUser(final UserModel userModel) async {
    try {
      await userCollectionReference.doc(userModel.id).update(userModel.toJson());
    } on FirebaseException catch (e) {
      throw Failure(e.message);
    } catch (e) {
      throw Failure('Failed to update user data: $e');
    }
  }
}
