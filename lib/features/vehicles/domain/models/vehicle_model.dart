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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VehicleModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
