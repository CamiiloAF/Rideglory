import 'package:rideglory/features/soat/domain/models/soat_model.dart';

export 'package:rideglory/features/soat/domain/models/soat_model.dart' show SoatStatus;

class VehicleModel {
  final String? id;
  final String name;
  final String? brand;
  final String? model;
  final int? year;
  final int currentMileage;
  final String? licensePlate;
  final String? vin;
  final DateTime? purchaseDate;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  final bool isMainVehicle;
  final SoatStatus? soatStatus;
  final DateTime? soatExpiryDate;
  final String? color;
  final String? engine;
  final String? horsepower;
  final String? torque;
  final String? weight;

  const VehicleModel({
    this.id,
    required this.name,
    this.brand,
    this.model,
    this.year,
    required this.currentMileage,
    this.licensePlate,
    this.vin,
    this.purchaseDate,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.isMainVehicle = false,
    this.soatStatus,
    this.soatExpiryDate,
    this.color,
    this.engine,
    this.horsepower,
    this.torque,
    this.weight,
  });

  VehicleModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    int? year,
    int? currentMileage,
    String? licensePlate,
    String? vin,
    DateTime? purchaseDate,
    String? imageUrl,
    DateTime? createdDate,
    DateTime? updatedDate,
    bool? isArchived,
    bool? isMainVehicle,
    SoatStatus? soatStatus,
    DateTime? soatExpiryDate,
    Object? color = _unset,
    Object? engine = _unset,
    Object? horsepower = _unset,
    Object? torque = _unset,
    Object? weight = _unset,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      currentMileage: currentMileage ?? this.currentMileage,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdDate ?? createdAt,
      updatedAt: updatedDate ?? updatedAt,
      isArchived: isArchived ?? this.isArchived,
      isMainVehicle: isMainVehicle ?? this.isMainVehicle,
      soatStatus: soatStatus ?? this.soatStatus,
      soatExpiryDate: soatExpiryDate ?? this.soatExpiryDate,
      color: color == _unset ? this.color : color as String?,
      engine: engine == _unset ? this.engine : engine as String?,
      horsepower: horsepower == _unset ? this.horsepower : horsepower as String?,
      torque: torque == _unset ? this.torque : torque as String?,
      weight: weight == _unset ? this.weight : weight as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VehicleModel &&
            id == other.id &&
            name == other.name &&
            brand == other.brand &&
            model == other.model &&
            year == other.year &&
            currentMileage == other.currentMileage &&
            licensePlate == other.licensePlate &&
            vin == other.vin &&
            purchaseDate == other.purchaseDate &&
            imageUrl == other.imageUrl &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            isArchived == other.isArchived &&
            isMainVehicle == other.isMainVehicle &&
            soatStatus == other.soatStatus &&
            soatExpiryDate == other.soatExpiryDate &&
            color == other.color &&
            engine == other.engine &&
            horsepower == other.horsepower &&
            torque == other.torque &&
            weight == other.weight;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    brand,
    model,
    year,
    currentMileage,
    licensePlate,
    vin,
    purchaseDate,
    imageUrl,
    createdAt,
    updatedAt,
    isArchived,
    isMainVehicle,
    soatStatus,
    soatExpiryDate,
    color,
    engine,
    horsepower,
    torque,
    weight,
  ]);
}

const _unset = Object();
