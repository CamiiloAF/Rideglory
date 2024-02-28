import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../core/exceptions/failure.dart';
import '../../../../../users/domain/entities/user_model.dart';
import '../../../domain/repositories/sign_up_repository_contract.dart';

part 'sign_up_cubit.freezed.dart';
part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({required final SignUpRepositoryContract signUpRepositoryContract})
      : _signUpRepositoryContract = signUpRepositoryContract,
        super(const SignUpState.initial());

  final SignUpRepositoryContract _signUpRepositoryContract;

  Future<void> signUp(final UserModel userModel) async {
    emit(const SignUpState.loading());
    try {
      await _signUpRepositoryContract.signUp(userModel);
      emit(const SignUpState.success());
    } on Failure catch (e) {
      emit(SignUpState.error(e.toString()));
    }
  }

  User getFirebaseUser() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return user;
    } else {
      throw Failure('User not found');
    }
  }
}
