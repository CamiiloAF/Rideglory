import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
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

  /// Canal lateral para errores transitorios de acciones (aprobar/rechazar/
  /// solicitar edición). Se mantiene aparte del [state] de lista para no
  /// reemplazar el listado por una pantalla de error; la página lo escucha y
  /// muestra un mensaje (SnackBar).
  final StreamController<DomainException> _actionErrorController =
      StreamController<DomainException>.broadcast();

  Stream<DomainException> get actionErrors => _actionErrorController.stream;

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

  RegistrationStatus? _updateRegistrationStatusLocally(
    String registrationId,
    RegistrationStatus status,
  ) {
    final index = _registrations.indexWhere((r) => r.id == registrationId);
    if (index < 0) return null;
    final previousStatus = _registrations[index].status;
    final updated = _registrations[index].copyWith(status: status);
    final newList = List<EventRegistrationModel>.from(_registrations)
      ..[index] = updated;
    _registrations = newList;
    final eventId = _eventId;
    if (eventId != null) {
      _cache.updateStatus(eventId, registrationId, status);
    }

    // `EventRegistrationModel.==` solo compara por id, así que el deep equality
    // de la lista da true aunque el status haya cambiado y Bloc descartaría el
    // emit. Forzamos un cambio visible emitiendo un estado intermedio antes del
    // nuevo data para que la UI refleje el nuevo estado al volver del detalle.
    emit(const ResultState.initial());
    emit(ResultState.data(data: _registrations));
    return previousStatus;
  }

  /// Actualización optimista: refleja el nuevo estado de inmediato y, si el
  /// backend falla, revierte al estado previo para no mostrar un resultado
  /// engañoso.
  Future<void> _updateStatusOptimistically(
    String registrationId,
    RegistrationStatus newStatus,
    Future<Either<DomainException, EventRegistrationModel>> Function(String)
    action,
  ) async {
    final previousStatus = _updateRegistrationStatusLocally(
      registrationId,
      newStatus,
    );
    if (previousStatus == null) return;

    final result = await action(registrationId);
    result.fold((error) {
      _updateRegistrationStatusLocally(registrationId, previousStatus);
      _actionErrorController.add(error);
    }, (_) {});
  }

  Future<void> approveRegistration(String registrationId) {
    return _updateStatusOptimistically(
      registrationId,
      RegistrationStatus.approved,
      _approveUseCase.call,
    );
  }

  Future<void> rejectRegistration(String registrationId) {
    return _updateStatusOptimistically(
      registrationId,
      RegistrationStatus.rejected,
      _rejectUseCase.call,
    );
  }

  Future<void> setReadyForEdit(String registrationId) {
    return _updateStatusOptimistically(
      registrationId,
      RegistrationStatus.readyForEdit,
      _setReadyForEditUseCase.call,
    );
  }

  @override
  Future<void> close() {
    _actionErrorController.close();
    return super.close();
  }
}
