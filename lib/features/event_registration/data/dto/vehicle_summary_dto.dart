import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/event_registration/domain/model/vehicle_summary_model.dart';

part 'vehicle_summary_dto.g.dart';

@JsonSerializable()
class VehicleSummaryDto {
  const VehicleSummaryDto({
    required this.id,
    this.brand,
    this.model,
    this.licensePlate,
    this.vin,
  });

  final String id;
  final String? brand;
  final String? model;
  final String? licensePlate;
  final String? vin;

  factory VehicleSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleSummaryDtoToJson(this);

  VehicleSummaryModel toModel() => VehicleSummaryModel(
    id: id,
    brand: brand,
    model: model,
    licensePlate: licensePlate,
    vin: vin,
  );
}
