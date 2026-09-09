import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/consent_entry.dart';
import '../../domain/usecases/get_consent_log_usecase.dart';

@injectable
class ConsentLogCubit extends Cubit<ResultState<List<ConsentEntry>>> {
  ConsentLogCubit(this._getConsentLog) : super(const ResultState.initial());

  final GetConsentLogUseCase _getConsentLog;

  Future<void> load() async {
    emit(const ResultState.loading());
    final result = await _getConsentLog();
    emit(
      result.fold(
        (error) => ResultState.error(error: error),
        (entries) => entries.isEmpty
            ? const ResultState.empty()
            : ResultState.data(data: entries),
      ),
    );
  }
}
