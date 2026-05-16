import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/vehicles/domain/models/soat_model.dart';

part 'soat_dto.g.dart';

@JsonSerializable()
class SoatDto {
  final String? id;
  final String vehicleId;
  final String policyNumber;
  final String startDate;
  final String expiryDate;
  final String insurer;
  final String? documentUrl;

  const SoatDto({
    this.id,
    required this.vehicleId,
    required this.policyNumber,
    required this.startDate,
    required this.expiryDate,
    required this.insurer,
    this.documentUrl,
  });

  factory SoatDto.fromJson(Map<String, dynamic> json) =>
      _$SoatDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SoatDtoToJson(this);

  SoatModel toModel() => SoatModel(
        id: id,
        vehicleId: vehicleId,
        policyNumber: policyNumber,
        startDate: DateTime.parse(startDate),
        expiryDate: DateTime.parse(expiryDate),
        insurer: insurer,
        documentUrl: documentUrl,
      );
}
