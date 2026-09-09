import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';

/// Estado del envío del enlace de recuperación de contraseña.
@injectable
class ForgotPasswordCubit extends Cubit<ResultState<Unit>> {
  ForgotPasswordCubit(this._sendPasswordReset)
    : super(const ResultState.initial());

  final SendPasswordResetUseCase _sendPasswordReset;

  Future<void> sendResetLink({required String email}) async {
    emit(const ResultState.loading());
    final result = await _sendPasswordReset(email: email);
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (_) => const ResultState.data(data: unit),
      ),
    );
  }
}
