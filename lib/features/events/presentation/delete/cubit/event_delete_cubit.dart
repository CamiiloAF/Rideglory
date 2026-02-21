import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/use_cases/delete_event_use_case.dart';

@injectable
class EventDeleteCubit extends Cubit<ResultState<Nothing>> {
  EventDeleteCubit(this._deleteEventUseCase)
    : super(const ResultState.initial());

  final DeleteEventUseCase _deleteEventUseCase;

  Future<void> deleteEvent(String eventId) async {
    emit(const ResultState.loading());

    final result = await _deleteEventUseCase(eventId);

    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (_) => emit(ResultState.data(data: Nothing())),
    );
  }
}
