import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_my_registrations_use_case.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';

class MyRegistrationsCubit
    extends Cubit<ResultState<List<RegistrationWithEvent>>> {
  MyRegistrationsCubit(
    this._getMyRegistrationsUseCase,
    this._cancelRegistrationUseCase,
    this._getEventByIdUseCase,
  ) : super(const ResultState.initial());

  final GetMyRegistrationsUseCase _getMyRegistrationsUseCase;
  final CancelEventRegistrationUseCase _cancelRegistrationUseCase;
  final GetEventByIdUseCase _getEventByIdUseCase;

  List<EventRegistrationModel> _registrations = [];
  Map<String, EventModel> _eventByEventId = {};
  Set<RegistrationStatus> _statusFilter = const {};
  String _searchQuery = '';

  Set<RegistrationStatus> get statusFilter => _statusFilter;

  bool get hasFilters => _statusFilter.isNotEmpty;

  Future<void> fetchMyRegistrations() async {
    emit(const ResultState.loading());
    final result = await _getMyRegistrationsUseCase();
    await result.fold(
      (error) async => emit(ResultState.error(error: error)),
      (registrations) async {
        _registrations = registrations;
        if (registrations.isEmpty) {
          emit(const ResultState.empty());
          return;
        }
        final eventIds =
            registrations.map((r) => r.eventId).toSet().toList();
        final eventResults = await Future.wait(
          eventIds.map((id) => _getEventByIdUseCase(id)),
        );
        _eventByEventId = {};
        for (var i = 0; i < eventIds.length; i++) {
          eventResults[i].fold(
            (_) => null,
            (event) => _eventByEventId[eventIds[i]] = event,
          );
        }
        _emitFiltered();
      },
    );
  }

  void updateStatusFilter(Set<RegistrationStatus> statuses) {
    _statusFilter = statuses;
    _emitFiltered();
  }

  void clearFilters() {
    _statusFilter = const {};
    _emitFiltered();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _emitFiltered();
  }

  void _emitFiltered() {
    var list = _registrations
        .map(
          (r) => RegistrationWithEvent(
            registration: r,
            event: _eventByEventId[r.eventId],
          ),
        )
        .toList();
    if (_statusFilter.isNotEmpty) {
      list = list
          .where((e) => _statusFilter.contains(e.registration.status))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        final registration = e.registration;
        final event = e.event;
        final fullName = registration.fullName.toLowerCase();
        final eventName = event?.name.toLowerCase() ?? '';
        return fullName.contains(q) || eventName.contains(q);
      }).toList();
    }
    if (_registrations.isEmpty) {
      emit(const ResultState.empty());
    } else {
      emit(ResultState.data(data: list));
    }
  }

  Future<bool> cancelRegistration(String registrationId) async {
    final result = await _cancelRegistrationUseCase(registrationId);
    return result.fold((error) => false, (_) {
      final updatedRegistration = _registrations
          .firstWhere((r) => r.id == registrationId)
          .copyWith(status: RegistrationStatus.cancelled);
      onChangeRegistration(updatedRegistration);
      return true;
    });
  }

  void onChangeRegistration(EventRegistrationModel updatedRegistration) {
    final index =
        _registrations.indexWhere((r) => r.id == updatedRegistration.id);
    if (index == -1) {
      _registrations.add(updatedRegistration);
    } else {
      _registrations[index] = updatedRegistration;
    }
    _emitFiltered();
  }
}
