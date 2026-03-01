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

  late List<EventRegistrationModel> _registrations;

  Future<void> fetchMyRegistrations() async {
    emit(const ResultState.loading());
    final result = await _getMyRegistrationsUseCase();
    result.fold((error) => emit(ResultState.error(error: error)), (
      registrations,
    ) {
      _registrations = registrations;

      registrations.isEmpty
          ? emit(const ResultState.empty())
          : emit(ResultState.data(data: registrations));
    });
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

  void onChangeRegistration(EventRegistrationModel updatedRegistrations) {
    emit(const ResultState.loading());

    final index = _registrations.indexWhere(
      (r) => r.id == updatedRegistrations.id,
    );
    if (index == -1) {
      _registrations.add(updatedRegistrations);
    } else {
      _registrations[index] = updatedRegistrations;
    }

    emit(ResultState.data(data: _registrations));
  }
}
