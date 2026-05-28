import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/event_registration/domain/model/vehicle_summary_model.dart';

part 'vehicle_summary_dto.g.dart';

@JsonSerializable()
class VehicleSummaryDto extends VehicleSummaryModel {
  const VehicleSummaryDto({
    required super.id,
    super.brand,
    super.model,
    super.licensePlate,
    super.vin,
  });

  factory VehicleSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleSummaryDtoToJson(this);
}

extension VehicleSummaryModelExtension on VehicleSummaryModel {
  Map<String, dynamic> toJson() => VehicleSummaryDto(
    id: id,
    brand: brand,
    model: model,
    licensePlate: licensePlate,
    vin: vin,
  ).toJson();
}
