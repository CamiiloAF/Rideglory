import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../profile/domain/blood_type.dart';
import '../../../profile/domain/usecases/get_profile_usecase.dart';
import '../../domain/register_for_event_params.dart';
import '../../domain/registration_status.dart';
import '../../domain/usecases/get_my_vehicles_for_event_use_case.dart';
import '../../domain/usecases/register_for_event_use_case.dart';
import 'registration_state.dart';

/// Pantalla EV4: precarga desde `profiles` y confirma la inscripción con
/// el snapshot legal. Los sellos de consentimiento los pone el servidor,
/// nunca este cubit.
@injectable
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this._getProfile, this._getVehicles, this._register)
    : super(const RegistrationState());

  final GetProfileUseCase _getProfile;
  final GetMyVehiclesForEventUseCase _getVehicles;
  final RegisterForEventUseCase _register;

  Future<void> load() async {
    emit(
      state.copyWith(
        profile: const ResultState.loading(),
        vehicles: const ResultState.loading(),
      ),
    );
    await Future.wait([_loadProfile(), _loadVehicles()]);
  }

  Future<void> _loadProfile() async {
    final result = await _getProfile();
    result.fold(
      (error) => emit(state.copyWith(profile: ResultState.error(error: error))),
      (profile) =>
          emit(state.copyWith(profile: ResultState.data(data: profile))),
    );
  }

  Future<void> _loadVehicles() async {
    final result = await _getVehicles();
    result.fold(
      (error) =>
          emit(state.copyWith(vehicles: ResultState.error(error: error))),
      (vehicles) => emit(
        state.copyWith(
          vehicles: ResultState.data(data: vehicles),
          selectedVehicleId: vehicles.isEmpty ? null : vehicles.first.id,
        ),
      ),
    );
  }

  void selectVehicle(String? vehicleId) =>
      emit(state.copyWith(selectedVehicleId: vehicleId));

  void toggleShareMedicalInfo(bool value) =>
      emit(state.copyWith(shareMedicalInfo: value));

  void toggleAllowOrganizerContact(bool value) =>
      emit(state.copyWith(allowOrganizerContact: value));

  void toggleAcceptsRisk(bool value) =>
      emit(state.copyWith(acceptsRisk: value));

  static const String consentVersion = 'v1.0';

  Future<void> submit(String eventId) async {
    if (!state.canSubmit) return;
    final profile = state.profile.whenOrNull(data: (profile) => profile);
    if (profile == null) return;

    emit(state.copyWith(submission: const ResultState.loading()));

    final params = RegisterForEventParams(
      eventId: eventId,
      fullName: profile.fullName ?? '',
      phone: profile.phone ?? '',
      emergencyContactName: profile.emergencyContactName ?? '',
      emergencyContactPhone: profile.emergencyContactPhone ?? '',
      shareMedicalInfo: state.shareMedicalInfo,
      allowOrganizerContact: state.allowOrganizerContact,
      acceptsRisk: state.acceptsRisk,
      consentVersion: consentVersion,
      vehicleId: state.selectedVehicleId,
      bloodType: state.shareMedicalInfo
          ? _toEventBloodType(profile.bloodType)
          : null,
      eps: state.shareMedicalInfo ? profile.eps : null,
    );

    final result = await _register(params);
    result.fold(
      (error) =>
          emit(state.copyWith(submission: ResultState.error(error: error))),
      (_) =>
          emit(state.copyWith(submission: const ResultState.data(data: unit))),
    );
  }
}

EventBloodType? _toEventBloodType(BloodType? bloodType) {
  if (bloodType == null) return null;
  return switch (bloodType) {
    BloodType.oPositive => EventBloodType.oPositive,
    BloodType.oNegative => EventBloodType.oNegative,
    BloodType.aPositive => EventBloodType.aPositive,
    BloodType.aNegative => EventBloodType.aNegative,
    BloodType.bPositive => EventBloodType.bPositive,
    BloodType.bNegative => EventBloodType.bNegative,
    BloodType.abPositive => EventBloodType.abPositive,
    BloodType.abNegative => EventBloodType.abNegative,
  };
}
