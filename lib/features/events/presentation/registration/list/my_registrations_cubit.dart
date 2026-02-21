import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registrations_use_case.dart';

// TODO agregar un estado para cuando se cancela una inscripción, para mostrar un mensaje de éxito o error
class MyRegistrationsCubit
    extends Cubit<ResultState<List<EventRegistrationModel>>> {
  MyRegistrationsCubit(
    this._getMyRegistrationsUseCase,
    this._cancelRegistrationUseCase,
  ) : super(const ResultState.initial());

  final GetMyRegistrationsUseCase _getMyRegistrationsUseCase;
  final CancelEventRegistrationUseCase _cancelRegistrationUseCase;

  Future<void> fetchMyRegistrations() async {
    emit(const ResultState.loading());
    final result = await _getMyRegistrationsUseCase();
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (registrations) => registrations.isEmpty
          ? emit(const ResultState.empty())
          : emit(ResultState.data(data: registrations)),
    );
  }

  Future<void> cancelRegistration(String registrationId) async {
    final result = await _cancelRegistrationUseCase(registrationId);
    result.fold((error) => null, (_) => fetchMyRegistrations());
  }
}
