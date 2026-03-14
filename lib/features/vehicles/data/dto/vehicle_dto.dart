import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'vehicle_dto.g.dart';

@JsonSerializable()
class VehicleDto extends VehicleModel {
  const VehicleDto({
    super.id,
    required super.name,
    super.brand,
    super.model,
    super.year,
    required super.currentMileage,
    super.licensePlate,
    super.vin,
    super.purchaseDate,
    super.imageUrl,
    super.createdDate,
    super.updatedDate,
    super.isArchived,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleDtoToJson(this);

  VehicleModel toModel() {
    return VehicleModel(
      id: id,
      name: name,
      brand: brand,
      model: model,
      year: year,
      currentMileage: currentMileage,
      licensePlate: licensePlate,
      vin: vin,
      purchaseDate: purchaseDate,
      imageUrl: imageUrl,
      createdDate: createdDate,
      updatedDate: updatedDate,
      isArchived: isArchived,
    );
  }
}

extension VehicleModelExtension on VehicleModel {
  Map<String, dynamic> toJson() => VehicleDto(
        id: id,
        name: name,
        brand: brand,
        model: model,
        year: year,
        currentMileage: currentMileage,
        licensePlate: licensePlate,
        vin: vin,
        purchaseDate: purchaseDate,
        imageUrl: imageUrl,
        createdDate: createdDate,
        updatedDate: updatedDate,
        isArchived: isArchived,
      ).toJson();
}
