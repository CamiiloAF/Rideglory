import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/approve_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_event_registrations_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_my_registration_for_event_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/reject_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/set_registration_ready_for_edit_use_case.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/publish_event_use_case.dart';
import 'package:rideglory/features/events/data/cache/attendees_cache.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/presentation/tracking/live_tracking_session_holder.dart';

part 'event_detail_state.dart';
part 'event_detail_cubit.freezed.dart';

class EventDetailCubit extends Cubit<EventDetailState> {
  EventDetailCubit(
    this._getMyRegistrationUseCase,
    this._cancelRegistrationUseCase,
    this._getEventByIdUseCase,
    this._updateEventUseCase,
    this._publishEventUseCase,
    this._getEventRegistrationsUseCase,
    this._approveRegistrationUseCase,
    this._rejectRegistrationUseCase,
    this._setReadyForEditUseCase,
    this._analytics,
    this._trackingRepository,
  ) : super(
        const EventDetailState(
          registrationResult: ResultState.initial(),
          eventResult: ResultState.initial(),
          lastUpdatedEventResult: null,
        ),
      );

  final GetEventByIdUseCase _getEventByIdUseCase;
  final GetMyRegistrationForEventUseCase _getMyRegistrationUseCase;
  final CancelEventRegistrationUseCase _cancelRegistrationUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final PublishEventUseCase _publishEventUseCase;
  final GetEventRegistrationsUseCase _getEventRegistrationsUseCase;
  final ApproveRegistrationUseCase _approveRegistrationUseCase;
  final RejectRegistrationUseCase _rejectRegistrationUseCase;
  final SetRegistrationReadyForEditUseCase _setReadyForEditUseCase;
  final AnalyticsService _analytics;
  final TrackingRepository _trackingRepository;

  EventRegistrationModel? _registration;
  String? _attendeesEventId;

  /// Carga la lista COMPLETA de inscripciones del evento (no `/me`).
  /// Siempre golpea el backend en cada entrada al detalle para mostrar el
  /// conteo real y refrescar el caché. El caché solo se usa downstream desde
  /// la pantalla de "Gestionar inscritos" para evitar una segunda llamada
  /// dentro de la misma sesión.
  Future<void> loadAttendees(String eventId) async {
    _attendeesEventId = eventId;
    emit(state.copyWith(attendeesResult: const ResultState.loading()));
    final result = await _getEventRegistrationsUseCase(eventId);
    result.fold(
      (error) => emit(
        state.copyWith(attendeesResult: ResultState.error(error: error)),
      ),
      (registrations) {
        getIt<AttendeesCache>().write(eventId, registrations);
        if (registrations.isEmpty) {
          emit(state.copyWith(attendeesResult: const ResultState.empty()));
        } else {
          emit(
            state.copyWith(
              attendeesResult: ResultState.data(data: registrations),
            ),
          );
        }
      },
    );
  }

  /// Actualiza localmente el estado de una inscripción y dispara la llamada
  /// al backend en segundo plano. Mantiene sincronizado el caché compartido
  /// para que la pantalla de gestión de inscritos refleje el cambio sin
  /// re-fetch.
  void _updateAttendeeStatusLocally(
    String registrationId,
    RegistrationStatus status,
  ) {
    final current = state.attendeesResult.maybeWhen(
      data: (regs) => regs,
      orElse: () => const <EventRegistrationModel>[],
    );
    final index = current.indexWhere((r) => r.id == registrationId);
    if (index < 0) return;
    final updated = current[index].copyWith(status: status);
    final newList = List<EventRegistrationModel>.from(current)
      ..[index] = updated;
    // `EventRegistrationModel.==` solo compara por id, así que el deep equality
    // de la lista da true aunque el status haya cambiado. Forzamos un cambio
    // visible para Bloc emitiendo un estado intermedio antes del nuevo data.
    emit(state.copyWith(attendeesResult: const ResultState.initial()));
    emit(state.copyWith(attendeesResult: ResultState.data(data: newList)));
    final eventId = _attendeesEventId;
    if (eventId != null) {
      getIt<AttendeesCache>().updateStatus(eventId, registrationId, status);
    }
  }

  Future<void> approveAttendee(String registrationId) async {
    _updateAttendeeStatusLocally(registrationId, RegistrationStatus.approved);
    unawaited(_approveRegistrationUseCase(registrationId));
  }

  Future<void> rejectAttendee(String registrationId) async {
    _updateAttendeeStatusLocally(registrationId, RegistrationStatus.rejected);
    unawaited(_rejectRegistrationUseCase(registrationId));
  }

  Future<void> setAttendeeReadyForEdit(String registrationId) async {
    _updateAttendeeStatusLocally(
      registrationId,
      RegistrationStatus.readyForEdit,
    );
    unawaited(_setReadyForEditUseCase(registrationId));
  }

  Future<void> loadEvent(String eventId) async {
    emit(state.copyWith(eventResult: const ResultState.loading()));
    final result = await _getEventByIdUseCase(eventId);
    result.fold(
      (error) =>
          emit(state.copyWith(eventResult: ResultState.error(error: error))),
      (event) {
        // Camino deep-link (EventDetailByIdPage): emitir event_detail_viewed
        // una sola vez aquí. EventDetailPage (camino lista/borrador) tiene su
        // propia emisión en el create: del BlocProvider; nunca emite ambos
        // (ver Fase 6, Riesgo #2).
        _analytics.logEvent(AnalyticsEvents.eventDetailViewed, {
          AnalyticsParams.eventType: event.eventType.apiValue,
          AnalyticsParams.eventState: event.state.name,
          AnalyticsParams.isOwner: 0, // No se conoce el uid aquí sin AuthCubit
          AnalyticsParams.isReadOnly: 0,
          AnalyticsParams.source: AnalyticsParams.sourceDeepLink,
        }).ignore();
        emit(state.copyWith(eventResult: ResultState.data(data: event)));
      },
    );
  }

  Future<void> loadMyRegistration(String eventId) async {
    emit(state.copyWith(registrationResult: const ResultState.loading()));
    final result = await _getMyRegistrationUseCase(eventId);
    result.fold(
      (error) => emit(
        state.copyWith(registrationResult: ResultState.error(error: error)),
      ),
      (registration) {
        _registration = registration;
        emit(
          state.copyWith(
            registrationResult: ResultState.data(data: registration),
          ),
        );
      },
    );
  }

  Future<bool> cancelRegistration(String registrationId) async {
    emit(state.copyWith(registrationResult: const ResultState.loading()));

    final result = await _cancelRegistrationUseCase(registrationId);
    if (isClosed) return false;
    return result.fold(
      (error) {
        emit(
          state.copyWith(registrationResult: ResultState.error(error: error)),
        );
        return false;
      },
      (_) {
        _registration = _registration!.copyWith(
          status: RegistrationStatus.cancelled,
        );

        updateRegistration(_registration!);
        return true;
      },
    );
  }

  void updateRegistration(EventRegistrationModel registration) {
    if (isClosed) return;
    emit(state.copyWith(registrationResult: const ResultState.loading()));

    _registration = registration;
    emit(
      state.copyWith(registrationResult: ResultState.data(data: registration)),
    );
  }

  void clearLastUpdatedEvent() {
    emit(state.copyWith(lastUpdatedEventResult: null));
  }

  Future<void> startEvent(EventModel event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }
    if (event.state != EventState.scheduled) {
      return;
    }

    emit(state.copyWith(lastUpdatedEventResult: const ResultState.loading()));

    final updated = event.copyWith(state: EventState.inProgress);
    final result = await _updateEventUseCase(updated);
    result.fold(
      (error) => emit(
        state.copyWith(lastUpdatedEventResult: ResultState.error(error: error)),
      ),
      (saved) {
        emit(
          state.copyWith(
            lastUpdatedEventResult: ResultState.data(data: saved),
            eventResult: ResultState.data(data: saved),
          ),
        );
      },
    );
  }

  Future<void> publishEvent(EventModel event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }

    emit(state.copyWith(lastUpdatedEventResult: const ResultState.loading()));

    final result = await _publishEventUseCase(id);
    result.fold(
      (error) => emit(
        state.copyWith(lastUpdatedEventResult: ResultState.error(error: error)),
      ),
      (saved) => emit(
        state.copyWith(
          lastUpdatedEventResult: ResultState.data(data: saved),
          eventResult: ResultState.data(data: saved),
        ),
      ),
    );
  }

  Future<void> stopEvent(EventModel event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }
    if (event.state != EventState.inProgress) {
      return;
    }

    emit(state.copyWith(lastUpdatedEventResult: const ResultState.loading()));

    // endRide: actualiza estado en backend a FINISHED y emite WS tracking.event.ended
    // a todos los riders conectados, en una sola llamada.
    final result = await _trackingRepository.endRide(id);
    await result.fold<Future<void>>(
      (error) async {
        emit(
          state.copyWith(
            lastUpdatedEventResult: ResultState.error(error: error),
          ),
        );
      },
      (_) async {
        final finished = event.copyWith(state: EventState.finished);
        await getIt<LiveTrackingSessionHolder>().stopSessionForEvent(id);
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            lastUpdatedEventResult: ResultState.data(data: finished),
            eventResult: ResultState.data(data: finished),
          ),
        );
      },
    );
  }
}
