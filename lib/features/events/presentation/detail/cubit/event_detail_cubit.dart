import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registration_for_event_use_case.dart';

class EventDetailCubit extends Cubit<ResultState<EventRegistrationModel?>> {
  EventDetailCubit(
    this._getMyRegistrationUseCase,
    this._cancelRegistrationUseCase,
  ) : super(const ResultState.initial());

  final GetMyRegistrationForEventUseCase _getMyRegistrationUseCase;
  final CancelEventRegistrationUseCase _cancelRegistrationUseCase;

  Future<void> loadMyRegistration(String eventId) async {
    emit(const ResultState.loading());
    final result = await _getMyRegistrationUseCase(eventId);
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (registration) => emit(ResultState.data(data: registration)),
    );
  }

  Future<bool> cancelRegistration(String registrationId) async {
    final result = await _cancelRegistrationUseCase(registrationId);
    return result.fold((error) => false, (_) {
      state.whenOrNull(
        data: (registration) {
          if (registration != null) {
            emit(
              ResultState.data(
                data: registration.copyWith(
                  status: RegistrationStatus.cancelled,
                ),
              ),
            );
          }
        },
      );
      return true;
    });
  }
}
