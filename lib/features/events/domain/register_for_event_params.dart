import 'package:freezed_annotation/freezed_annotation.dart';

import 'registration_status.dart';

part 'register_for_event_params.freezed.dart';

/// Lo que junta la pantalla de inscripción (EV4) antes de enviarlo. Los
/// sellos de tiempo de consentimiento (`risk_accepted_at`,
/// `medical_consent_at`) nunca viajan desde aquí: los pone el servidor al
/// insertar, a partir de que `acceptsRisk`/`shareMedicalInfo` vengan en
/// `true`.
@freezed
abstract class RegisterForEventParams with _$RegisterForEventParams {
  const factory RegisterForEventParams({
    required String eventId,
    required String fullName,
    required String phone,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required bool shareMedicalInfo,
    required bool allowOrganizerContact,
    required bool acceptsRisk,
    required String consentVersion,
    String? vehicleId,
    EventBloodType? bloodType,
    String? eps,
  }) = _RegisterForEventParams;
}
