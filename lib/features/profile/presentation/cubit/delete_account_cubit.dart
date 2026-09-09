import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/profile_error_code.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import 'delete_account_state.dart';

@injectable
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit(this._deleteAccount)
    : super(const DeleteAccountState.initial());

  final DeleteAccountUseCase _deleteAccount;

  Future<void> confirm() async {
    emit(const DeleteAccountState.inProgress());
    final result = await _deleteAccount();
    emit(
      result.fold(
        (error) => error.message == ProfileErrorCode.activeEventOrganizer
            ? const DeleteAccountState.blocked()
            : DeleteAccountState.error(error: error),
        (_) => const DeleteAccountState.done(),
      ),
    );
  }
}
