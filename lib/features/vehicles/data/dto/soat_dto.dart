import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_soat_form_data.dart';

part 'soat_dto.g.dart';

// Shape-mismatch exception (not Pattern B):
// The API returns/accepts dates as ISO-8601 strings (String), while
// [VehicleSoatFormData] stores them as [DateTime]. This DTO acts as the
// serialization boundary and converts between the two representations.
// Pattern B (XDto extends XModel) does not apply here because the field
// types differ (String ↔ DateTime).
@JsonSerializable()
class VehicleSoatFormDataDto {
  final String? id;
  final String vehicleId;
  final String? policyNumber;
  final String startDate;
  final String expiryDate;
  final String insurer;
  final String? documentUrl;

  const VehicleSoatFormDataDto({
    this.id,
    required this.vehicleId,
    this.policyNumber,
    required this.startDate,
    required this.expiryDate,
    required this.insurer,
    this.documentUrl,
  });

  factory VehicleSoatFormDataDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleSoatFormDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleSoatFormDataDtoToJson(this);

  VehicleSoatFormData toFormData() => VehicleSoatFormData(
    id: id,
    vehicleId: vehicleId,
    policyNumber: policyNumber,
    startDate: DateTime.parse(startDate),
    expiryDate: DateTime.parse(expiryDate),
    insurer: insurer,
    documentUrl: documentUrl,
  );
}

extension VehicleSoatFormDataExtension on VehicleSoatFormData {
  Map<String, dynamic> toJson() => VehicleSoatFormDataDto(
    id: id,
    vehicleId: vehicleId,
    policyNumber: policyNumber,
    startDate: startDate.toIso8601String(),
    expiryDate: expiryDate.toIso8601String(),
    insurer: insurer,
    documentUrl: documentUrl,
  ).toJson();
}
