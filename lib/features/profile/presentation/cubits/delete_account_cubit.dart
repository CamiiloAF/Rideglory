import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/users/domain/use_cases/delete_account_use_case.dart';

/// Cubit local de una sola pantalla (`DeleteAccountConfirmationPage`).
///
/// No se registra en el `MultiBlocProvider` raíz — vive en un `BlocProvider`
/// local dentro de la página, mismo criterio que `EditProfileCubit` y
/// `AnalyticsConsentCubit`.
@injectable
class DeleteAccountCubit extends Cubit<ResultState<Nothing>> {
  DeleteAccountCubit(this._useCase) : super(const ResultState.initial());

  final DeleteAccountUseCase _useCase;

  Future<void> deleteAccount() async {
    if (state is Loading<Nothing>) return;
    emit(const ResultState.loading());
    final result = await _useCase();
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (nothing) => emit(ResultState.data(data: nothing)),
    );
  }
}
