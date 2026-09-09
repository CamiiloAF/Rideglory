import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';

/// Envío del formulario de correo (login o registro). La sesión resultante
/// la observa `AuthCubit`; este cubit solo modela el estado de la petición
/// en curso para la pantalla `EmailAuthPage`.
@injectable
class EmailAuthCubit extends Cubit<ResultState<Unit>> {
  EmailAuthCubit(this._signInWithEmail, this._signUpWithEmail)
    : super(const ResultState.initial());

  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;

  Future<void> signIn({required String email, required String password}) async {
    emit(const ResultState.loading());
    final result = await _signInWithEmail(email: email, password: password);
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (_) => const ResultState.data(data: unit),
      ),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    emit(const ResultState.loading());
    final result = await _signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (_) => const ResultState.data(data: unit),
      ),
    );
  }

  void reset() => emit(const ResultState.initial());
}
