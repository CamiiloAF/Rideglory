import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/approve_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_event_registrations_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/reject_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/set_registration_ready_for_edit_use_case.dart';
import 'package:rideglory/features/events/data/cache/attendees_cache.dart';

class AttendeesCubit extends Cubit<ResultState<List<EventRegistrationModel>>> {
  AttendeesCubit(
    this._getRegistrationsUseCase,
    this._approveUseCase,
    this._rejectUseCase,
    this._setReadyForEditUseCase,
    this._cache,
  ) : super(const ResultState.initial());

  final GetEventRegistrationsUseCase _getRegistrationsUseCase;
  final ApproveRegistrationUseCase _approveUseCase;
  final RejectRegistrationUseCase _rejectUseCase;
  final SetRegistrationReadyForEditUseCase _setReadyForEditUseCase;
  final AttendeesCache _cache;

  String? _eventId;
  List<EventRegistrationModel> _registrations = [];

  /// Hidrata desde el caché compartido si hay datos no vacíos para evitar
  /// repetir la llamada al endpoint cuando se viene desde el detalle del
  /// evento. Pasar [forceRefresh] (pull-to-refresh) salta el caché, llama al
  /// backend y reescribe el caché con la respuesta.
  Future<void> fetchAttendees(
    String eventId, {
    bool forceRefresh = false,
  }) async {
    _eventId = eventId;
    if (!forceRefresh) {
      final cached = _cache.read(eventId);
      if (cached != null && cached.isNotEmpty) {
        _registrations = List<EventRegistrationModel>.from(cached);
        emit(ResultState.data(data: _registrations));
        return;
      }
    }
    emit(const ResultState.loading());
    final result = await _getRegistrationsUseCase(eventId);
    result.fold((error) => emit(ResultState.error(error: error)), (
      registrations,
    ) {
      _registrations = registrations;
      _cache.write(eventId, registrations);

      registrations.isEmpty
          ? emit(const ResultState.empty())
          : emit(ResultState.data(data: _registrations));
    });
  }

  void _updateRegistrationStatusLocally(
    String registrationId,
    RegistrationStatus status,
  ) {
    final index = _registrations.indexWhere((r) => r.id == registrationId);
    if (index < 0) return;
    final updated = _registrations[index].copyWith(status: status);
    final newList = List<EventRegistrationModel>.from(_registrations)
      ..[index] = updated;
    _registrations = newList;
    final eventId = _eventId;
    if (eventId != null) {
      _cache.updateStatus(eventId, registrationId, status);
    }

    emit(const ResultState.initial());
    emit(ResultState.data(data: _registrations));
  }

  Future<void> approveRegistration(String registrationId) async {
    _updateRegistrationStatusLocally(
      registrationId,
      RegistrationStatus.approved,
    );
    unawaited(_approveUseCase(registrationId));
  }

  Future<void> rejectRegistration(String registrationId) async {
    _updateRegistrationStatusLocally(
      registrationId,
      RegistrationStatus.rejected,
    );
    unawaited(_rejectUseCase(registrationId));
  }

  Future<void> setReadyForEdit(String registrationId) async {
    final result = await _setReadyForEditUseCase(registrationId);
    result.fold(
      (error) => null,
      (_) => _eventId != null ? fetchAttendees(_eventId!) : null,
    );
  }
}
