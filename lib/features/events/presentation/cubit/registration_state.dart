import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../../profile/domain/profile.dart';
import '../../domain/event_vehicle_option.dart';

part 'registration_state.freezed.dart';

/// Pantalla de inscripción EV4. `profile` decide si se muestra el
/// formulario o el estado "perfil incompleto" (Mt9ij).
@freezed
abstract class RegistrationState with _$RegistrationState {
  const factory RegistrationState({
    @Default(ResultState<Profile>.initial()) ResultState<Profile> profile,
    @Default(ResultState<List<EventVehicleOption>>.initial())
    ResultState<List<EventVehicleOption>> vehicles,
    String? selectedVehicleId,
    @Default(false) bool shareMedicalInfo,
    @Default(false) bool allowOrganizerContact,
    @Default(false) bool acceptsRisk,
    @Default(ResultState<Unit>.initial()) ResultState<Unit> submission,
  }) = _RegistrationState;

  const RegistrationState._();

  bool get isSubmitting => submission is Loading<Unit>;

  bool get isProfileComplete {
    final data = profile.whenOrNull(data: (profile) => profile);
    if (data == null) return false;
    return (data.fullName?.trim().isNotEmpty ?? false) &&
        (data.phone?.trim().isNotEmpty ?? false) &&
        data.hasEmergencyContact;
  }

  bool get canSubmit => isProfileComplete && acceptsRisk && !isSubmitting;
}
