import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_my_registration_for_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
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

  EventRegistrationModel? _registration;

  Future<void> loadEvent(String eventId) async {
    emit(state.copyWith(eventResult: const ResultState.loading()));
    final result = await _getEventByIdUseCase(eventId);
    result.fold(
      (error) =>
          emit(state.copyWith(eventResult: ResultState.error(error: error))),
      (event) =>
          emit(state.copyWith(eventResult: ResultState.data(data: event))),
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

  Future<void> stopEvent(EventModel event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }
    if (event.state != EventState.inProgress) {
      return;
    }

    emit(state.copyWith(lastUpdatedEventResult: const ResultState.loading()));

    final updated = event.copyWith(state: EventState.finished);
    final result = await _updateEventUseCase(updated);
    await result.fold<Future<void>>(
      (error) async {
        emit(
          state.copyWith(
            lastUpdatedEventResult: ResultState.error(error: error),
          ),
        );
      },
      (saved) async {
        await getIt<LiveTrackingSessionHolder>().stopSessionForEvent(id);
        if (isClosed) {
          return;
        }
        emit(
          state.copyWith(
            lastUpdatedEventResult: ResultState.data(data: saved),
            eventResult: ResultState.data(data: saved),
          ),
        );
      },
    );
  }
}
