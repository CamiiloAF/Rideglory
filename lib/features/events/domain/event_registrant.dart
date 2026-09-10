import 'package:freezed_annotation/freezed_annotation.dart';

import 'registration_status.dart';

part 'event_registrant.freezed.dart';

/// Un inscrito visto por el organizador, desde
/// `event_registrations_for_organizer`. `phone`, `bloodType`, `eps` y el
/// contacto de emergencia ya vienen enmascarados por la vista según los
/// opt-ins del rider: si son `null` aquí es porque no compartió el dato,
/// nunca porque el cliente lo filtró.
@freezed
abstract class EventRegistrant with _$EventRegistrant {
  const factory EventRegistrant({
    required String id,
    required String userId,
    required String fullName,
    required RegistrationStatus status,
    required bool shareMedicalInfo,
    required bool allowOrganizerContact,
    String? vehicleName,
    String? phone,
    EventBloodType? bloodType,
    String? eps,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) = _EventRegistrant;
}
