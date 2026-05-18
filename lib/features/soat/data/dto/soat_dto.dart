import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';

part 'soat_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class SoatDto {
  const SoatDto({
    required this.id,
    required this.vehicleId,
    this.policyNumber,
    this.startDate,
    required this.expiryDate,
    this.insurer,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String vehicleId;
  final String? policyNumber;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String? insurer;
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SoatDto.fromJson(Map<String, dynamic> json) =>
      _$SoatDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SoatDtoToJson(this);

  SoatModel toModel() {
    return SoatModel(
      id: id,
      vehicleId: vehicleId,
      policyNumber: policyNumber,
      startDate: startDate,
      expiryDate: expiryDate ?? DateTime.now(),
      insurer: insurer,
      documentUrl: documentUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
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
