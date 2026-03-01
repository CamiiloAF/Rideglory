import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registration_for_event_use_case.dart';

part 'event_detail_state.dart';
part 'event_detail_cubit.freezed.dart';

class EventDetailCubit extends Cubit<EventDetailState> {
  EventDetailCubit(
    this._getMyRegistrationUseCase,
    this._cancelRegistrationUseCase,
    this._getEventByIdUseCase,
  ) : super(
        const EventDetailState(
          registrationResult: ResultState.initial(),
          eventResult: ResultState.initial(),
        ),
      );

  final GetEventByIdUseCase _getEventByIdUseCase;
  final GetMyRegistrationForEventUseCase _getMyRegistrationUseCase;
  final CancelEventRegistrationUseCase _cancelRegistrationUseCase;

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
}
