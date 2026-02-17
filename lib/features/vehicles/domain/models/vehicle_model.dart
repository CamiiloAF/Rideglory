import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

enum VehicleType {
  @JsonValue('car')
  car('Carro'),
  @JsonValue('motorcycle')
  motorcycle('Moto');

  final String label;
  const VehicleType(this.label);
}

class VehicleModel {
  final String? id;
  final String name;
  final String? brand;
  final String? model;
  final int? year;
  final int currentMileage;
  final DistanceUnit distanceUnit; // 'KM' or 'Miles'
  final VehicleType vehicleType;
  final String? licensePlate;
  final String? vin; // Vehicle Identification Number
  final DateTime? purchaseDate;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  const VehicleModel({
    this.id,
    required this.name,
    this.brand,
    this.model,
    this.year,
    required this.currentMileage,
    this.distanceUnit = DistanceUnit.kilometers,
    this.vehicleType = VehicleType.motorcycle,
    this.licensePlate,
    this.vin,
    this.purchaseDate,
    this.createdDate,
    this.updatedDate,
  });

  VehicleModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    int? year,
    int? currentMileage,
    DistanceUnit? distanceUnit,
    VehicleType? vehicleType,
    String? licensePlate,
    String? vin,
    DateTime? purchaseDate,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      currentMileage: currentMileage ?? this.currentMileage,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}
