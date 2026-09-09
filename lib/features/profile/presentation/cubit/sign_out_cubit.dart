import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';

/// Cerrar sesión desde Perfil. Delega en `auth`'s `SignOutUseCase`: la
/// sesión de Supabase es su dueña, `profile` no la duplica.
@injectable
class SignOutCubit extends Cubit<ResultState<Unit>> {
  SignOutCubit(this._signOut) : super(const ResultState.initial());

  final SignOutUseCase _signOut;

  Future<void> signOut() async {
    emit(const ResultState.loading());
    await _signOut();
    emit(const ResultState.data(data: unit));
  }
}
