import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/usecases/get_my_events_use_case.dart';
import '../../domain/usecases/get_upcoming_events_use_case.dart';
import 'events_list_state.dart';

/// Pantalla EV1: lista de rodadas con dos segmentos independientes.
@injectable
class EventsListCubit extends Cubit<EventsListState> {
  EventsListCubit(this._getUpcoming, this._getMine)
    : super(const EventsListState());

  final GetUpcomingEventsUseCase _getUpcoming;
  final GetMyEventsUseCase _getMine;

  Future<void> load() async {
    emit(
      state.copyWith(
        upcoming: const ResultState.loading(),
        mine: const ResultState.loading(),
      ),
    );
    await Future.wait([_loadUpcoming(), _loadMine()]);
  }

  Future<void> refreshCurrent() {
    return state.segment == EventsSegment.upcoming
        ? _loadUpcoming()
        : _loadMine();
  }

  Future<void> _loadUpcoming() async {
    emit(state.copyWith(upcoming: const ResultState.loading()));
    final result = await _getUpcoming();
    result.fold(
      (error) =>
          emit(state.copyWith(upcoming: ResultState.error(error: error))),
      (events) =>
          emit(state.copyWith(upcoming: ResultState.data(data: events))),
    );
  }

  Future<void> _loadMine() async {
    emit(state.copyWith(mine: const ResultState.loading()));
    final result = await _getMine();
    result.fold(
      (error) => emit(state.copyWith(mine: ResultState.error(error: error))),
      (events) => emit(state.copyWith(mine: ResultState.data(data: events))),
    );
  }

  void selectSegment(EventsSegment segment) {
    emit(state.copyWith(segment: segment));
  }
}
