import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/usecases/get_registrants_use_case.dart';
import '../../domain/usecases/set_registration_status_use_case.dart';
import 'registrants_state.dart';

@injectable
class RegistrantsCubit extends Cubit<RegistrantsState> {
  RegistrantsCubit(this._getRegistrants, this._setStatus)
    : super(const RegistrantsState());

  final GetRegistrantsUseCase _getRegistrants;
  final SetRegistrationStatusUseCase _setStatus;

  late String _eventId;

  Future<void> load(String eventId) async {
    _eventId = eventId;
    emit(state.copyWith(registrants: const ResultState.loading()));
    final result = await _getRegistrants(eventId);
    result.fold(
      (error) =>
          emit(state.copyWith(registrants: ResultState.error(error: error))),
      (registrants) => emit(
        state.copyWith(registrants: ResultState.data(data: registrants)),
      ),
    );
  }

  Future<void> retry() => load(_eventId);

  Future<void> setStatus(String registrationId, bool approve) async {
    final result = await _setStatus(registrationId, approve);
    if (result.isRight()) {
      await load(_eventId);
    }
  }
}
