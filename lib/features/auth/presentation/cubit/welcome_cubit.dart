import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/usecases/sign_in_with_apple_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';

/// Estado del acceso social (Google/Apple) en la bienvenida.
@injectable
class WelcomeCubit extends Cubit<ResultState<Unit>> {
  WelcomeCubit(this._signInWithGoogle, this._signInWithApple)
    : super(const ResultState.initial());

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInWithAppleUseCase _signInWithApple;

  Future<void> signInWithGoogle() async {
    emit(const ResultState.loading());
    final result = await _signInWithGoogle();
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (_) => const ResultState.data(data: unit),
      ),
    );
  }

  Future<void> signInWithApple() async {
    emit(const ResultState.loading());
    final result = await _signInWithApple();
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (_) => const ResultState.data(data: unit),
      ),
    );
  }

  void reset() => emit(const ResultState.initial());
}
