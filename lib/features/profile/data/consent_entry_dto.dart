import 'package:json_annotation/json_annotation.dart';

import '../domain/consent_entry.dart';

part 'consent_entry_dto.g.dart';

@JsonSerializable()
class ConsentEntryDto {
  ConsentEntryDto({
    required this.id,
    required this.kind,
    required this.version,
    required this.acceptedAt,
  });

  factory ConsentEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ConsentEntryDtoFromJson(json);

  final String id;
  final String kind;
  final String version;
  @JsonKey(name: 'accepted_at')
  final DateTime acceptedAt;

  Map<String, dynamic> toJson() => _$ConsentEntryDtoToJson(this);

  ConsentEntry toDomain() => ConsentEntry(
    id: id,
    kind: switch (kind) {
      'risk_acceptance' => ConsentKind.riskAcceptance,
      'medical_consent' => ConsentKind.medicalConsent,
      _ => ConsentKind.terms,
    },
    version: version,
    acceptedAt: acceptedAt,
  );
}
