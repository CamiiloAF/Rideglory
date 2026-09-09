import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/delete_account_summary.dart';
import '../../domain/usecases/get_delete_account_summary_usecase.dart';

@injectable
class DeleteAccountSummaryCubit
    extends Cubit<ResultState<DeleteAccountSummary>> {
  DeleteAccountSummaryCubit(this._getDeleteAccountSummary)
    : super(const ResultState.initial());

  final GetDeleteAccountSummaryUseCase _getDeleteAccountSummary;

  Future<void> load() async {
    emit(const ResultState.loading());
    final result = await _getDeleteAccountSummary();
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (summary) => ResultState.data(data: summary),
      ),
    );
  }
}
