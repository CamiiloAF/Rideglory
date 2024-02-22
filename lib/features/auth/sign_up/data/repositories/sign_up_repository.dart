import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rideglory/generated/l10n.dart';

import '../../../../../core/exceptions/failure.dart';
import '../../../../../core/models/user_model.dart';
import '../../domain/repositories/sign_up_repository.dart';

class SignUpRepository implements SignUpRepositoryContract {
  SignUpRepository({
    required this.userCollectionReference,
  });

  final CollectionReference userCollectionReference;

  @override
  Future<void> signUp(UserModel userModel) async {
    try {
      final doc = userCollectionReference.doc();
      await doc.set(userModel.copyWith(id: doc.id));
    } on Exception {
      throw Failure(AppStrings.current.signUpError);
    } catch (e) {
      throw Failure(e.toString());
    }
  }
}
