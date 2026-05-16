import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'vehicle_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
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
    super.createdAt,
    super.updatedAt,
    super.isArchived,
    super.isMainVehicle = false,
    super.soatStatus,
    super.soatExpiryDate,
    super.color,
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
      createdAt: createdAt,
      updatedAt: updatedAt,
      isArchived: isArchived,
      isMainVehicle: isMainVehicle,
      soatStatus: soatStatus,
      soatExpiryDate: soatExpiryDate,
      color: color,
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
    createdAt: createdAt,
    updatedAt: updatedAt,
    isArchived: isArchived,
    isMainVehicle: isMainVehicle,
    soatStatus: soatStatus,
    soatExpiryDate: soatExpiryDate,
    color: color,
  ).toJson();
}
