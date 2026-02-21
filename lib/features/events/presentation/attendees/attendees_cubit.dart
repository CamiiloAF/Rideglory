import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/use_cases/approve_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_registrations_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/reject_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/set_registration_ready_for_edit_use_case.dart';

// TODO agregar un estado para cuando se aprueba o rechaza una solicitud, para mostrar un mensaje de éxito o error
class AttendeesCubit
    extends Cubit<ResultState<List<EventRegistrationModel>>> {
  AttendeesCubit(
    this._getRegistrationsUseCase,
    this._approveUseCase,
    this._rejectUseCase,
    this._setReadyForEditUseCase,
  ) : super(const ResultState.initial());

  final GetEventRegistrationsUseCase _getRegistrationsUseCase;
  final ApproveRegistrationUseCase _approveUseCase;
  final RejectRegistrationUseCase _rejectUseCase;
  final SetRegistrationReadyForEditUseCase _setReadyForEditUseCase;

  String? _eventId;

  Future<void> fetchAttendees(String eventId) async {
    _eventId = eventId;
    emit(const ResultState.loading());
    final result = await _getRegistrationsUseCase(eventId);
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (registrations) => registrations.isEmpty
          ? emit(const ResultState.empty())
          : emit(ResultState.data(data: registrations)),
    );
  }

  Future<void> approveRegistration(String registrationId) async {
    final result = await _approveUseCase(registrationId);
    result.fold(
      (error) => null,
      (_) => _eventId != null ? fetchAttendees(_eventId!) : null,
    );
  }

  Future<void> rejectRegistration(String registrationId) async {
    final result = await _rejectUseCase(registrationId);
    result.fold(
      (error) => null,
      (_) => _eventId != null ? fetchAttendees(_eventId!) : null,
    );
  }

  Future<void> setReadyForEdit(String registrationId) async {
    final result = await _setReadyForEditUseCase(registrationId);
    result.fold(
      (error) => null,
      (_) => _eventId != null ? fetchAttendees(_eventId!) : null,
    );
  }
}
