import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';

part 'soat_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class SoatDto extends SoatModel {
  const SoatDto({
    required super.id,
    required super.vehicleId,
    super.policyNumber,
    super.startDate,
    // Backend contract guarantees non-null expiryDate when a SOAT exists (404 → no SOAT).
    required super.expiryDate,
    super.insurer,
    super.documentUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory SoatDto.fromJson(Map<String, dynamic> json) =>
      _$SoatDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SoatDtoToJson(this);
}

extension SoatModelToRequest on SoatModel {
  Map<String, dynamic> toRequestJson() {
    final map = <String, dynamic>{
      'expiryDate': expiryDate.toUtc().toIso8601String(),
    };
    if (policyNumber != null) map['policyNumber'] = policyNumber;
    if (startDate != null) {
      map['startDate'] = startDate!.toUtc().toIso8601String();
    }
    if (insurer != null) map['insurer'] = insurer;
    if (documentUrl != null) map['documentUrl'] = documentUrl;
    return map;
  }
}
