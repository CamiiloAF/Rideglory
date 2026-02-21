import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registration_for_event_use_case.dart';

class EventDetailCubit extends Cubit<ResultState<EventRegistrationModel?>> {
  EventDetailCubit(this._getMyRegistrationUseCase)
    : super(const ResultState.initial());

  final GetMyRegistrationForEventUseCase _getMyRegistrationUseCase;

  String? _eventId;

  Future<void> loadMyRegistration(String eventId) async {
    _eventId = eventId;
    emit(const ResultState.loading());
    final result = await _getMyRegistrationUseCase(eventId);
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (registration) => emit(ResultState.data(data: registration)),
    );
  }

  Future<void> cancelRegistration(String registrationId) async {
    // Handled externally via MyRegistrationsCubit, just refresh
    if (_eventId != null) loadMyRegistration(_eventId!);
  }
}
