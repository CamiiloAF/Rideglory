import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/usecases/add_route_change_use_case.dart';
import '../../domain/usecases/cancel_event_use_case.dart';
import '../../domain/usecases/cancel_my_registration_use_case.dart';
import '../../domain/usecases/get_event_detail_use_case.dart';
import '../../domain/usecases/get_route_changes_use_case.dart';
import '../../domain/usecases/start_event_use_case.dart';
import 'event_detail_state.dart';

/// Pantalla EV2. Un mismo cubit cubre las tres vistas del frame
/// (participante, inscrito, organizador): la vista se decide en
/// presentación según `event.isOwnedByMe` / `event.myRegistrationStatus`.
@injectable
class EventDetailCubit extends Cubit<EventDetailState> {
  EventDetailCubit(
    this._getDetail,
    this._getRouteChanges,
    this._cancelMyRegistration,
    this._startEvent,
    this._cancelEvent,
    this._addRouteChange,
  ) : super(const EventDetailState());

  final GetEventDetailUseCase _getDetail;
  final GetRouteChangesUseCase _getRouteChanges;
  final CancelMyRegistrationUseCase _cancelMyRegistration;
  final StartEventUseCase _startEvent;
  final CancelEventUseCase _cancelEvent;
  final AddRouteChangeUseCase _addRouteChange;

  late String _eventId;

  Future<void> load(String eventId) async {
    _eventId = eventId;
    emit(
      state.copyWith(
        event: const ResultState.loading(),
        routeChanges: const ResultState.loading(),
      ),
    );
    await Future.wait([_loadEvent(), _loadRouteChanges()]);
  }

  Future<void> _loadEvent() async {
    final result = await _getDetail(_eventId);
    result.fold(
      (error) => emit(state.copyWith(event: ResultState.error(error: error))),
      (event) => emit(state.copyWith(event: ResultState.data(data: event))),
    );
  }

  Future<void> _loadRouteChanges() async {
    final result = await _getRouteChanges(_eventId);
    result.fold(
      (error) =>
          emit(state.copyWith(routeChanges: ResultState.error(error: error))),
      (changes) =>
          emit(state.copyWith(routeChanges: ResultState.data(data: changes))),
    );
  }

  Future<bool> cancelMyRegistration() =>
      _runAction(() => _cancelMyRegistration(_eventId));

  Future<bool> startEvent() => _runAction(() => _startEvent(_eventId));

  Future<bool> cancelEvent() => _runAction(() => _cancelEvent(_eventId));

  Future<bool> changeRoute(String message) =>
      _runAction(() => _addRouteChange(_eventId, message));

  Future<bool> _runAction(
    Future<Either<DomainException, Unit>> Function() action,
  ) async {
    emit(state.copyWith(action: const ResultState.loading()));
    final result = await action();
    final success = result.isRight();
    result.fold(
      (error) => emit(state.copyWith(action: ResultState.error(error: error))),
      (_) => emit(state.copyWith(action: const ResultState.data(data: unit))),
    );
    if (success) {
      await load(_eventId);
    }
    return success;
  }
}
