import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/exceptions/failure.dart';
import '../../../../../generated/l10n.dart';
import '../../../../users/domain/entities/user_model.dart';
import '../../domain/repositories/sign_up_repository_contract.dart';

class SignUpRepository implements SignUpRepositoryContract {
  SignUpRepository({
    required this.userCollectionReference,
  });

  final CollectionReference userCollectionReference;

  @override
  Future<void> signUp(final UserModel userModel) async {
    try {
      await userCollectionReference.doc(userModel.id).set(userModel);
    } on FirebaseException catch (e) {
      throw Failure(e.message);
    } on Exception {
      throw Failure(AppStrings.current.signUpError);
    } catch (e) {
      throw Failure(e.toString());
    }
  }
}
