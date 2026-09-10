import 'package:freezed_annotation/freezed_annotation.dart';

import 'registration_status.dart';

part 'event_registration.freezed.dart';

/// La inscripción propia de un rider a una rodada. `riskAcceptedAt` y
/// `consentVersion` son evidencia legal sellada por el servidor — nunca se
/// construyen en el cliente.
@freezed
abstract class EventRegistration with _$EventRegistration {
  const factory EventRegistration({
    required String id,
    required String eventId,
    required RegistrationStatus status,
    required DateTime createdAt,
    String? vehicleId,
    DateTime? riskAcceptedAt,
    String? consentVersion,
  }) = _EventRegistration;
}
