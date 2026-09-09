import 'package:freezed_annotation/freezed_annotation.dart';

part 'consent_entry.freezed.dart';

enum ConsentKind { riskAcceptance, medicalConsent, terms }

/// Una fila de `consent_log`: evidencia legal de un consentimiento aceptado.
@freezed
abstract class ConsentEntry with _$ConsentEntry {
  const factory ConsentEntry({
    required String id,
    required ConsentKind kind,
    required String version,
    required DateTime acceptedAt,
  }) = _ConsentEntry;
}
