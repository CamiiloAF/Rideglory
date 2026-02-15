class VehicleModel {
  final String? id;
  final String name;
  final String? brand;
  final String? model;
  final int? year;
  final int currentMileage;
  final String distanceUnit; // 'KM' or 'Miles'
  final String? licensePlate;
  final String? vin; // Vehicle Identification Number
  final DateTime? purchaseDate;

  const VehicleModel({
    this.id,
    required this.name,
    this.brand,
    this.model,
    this.year,
    required this.currentMileage,
    this.distanceUnit = 'KM',
    this.licensePlate,
    this.vin,
    this.purchaseDate,
  });

  VehicleModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    int? year,
    int? currentMileage,
    String? distanceUnit,
    String? licensePlate,
    String? vin,
    DateTime? purchaseDate,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      currentMileage: currentMileage ?? this.currentMileage,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'currentMileage': currentMileage,
      'distanceUnit': distanceUnit,
      'licensePlate': licensePlate,
      'vin': vin,
      'purchaseDate': purchaseDate?.toIso8601String(),
    };
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      currentMileage: (json['currentMileage'] as num).toInt(),
      distanceUnit: json['distanceUnit'] as String? ?? 'KM',
      licensePlate: json['licensePlate'] as String?,
      vin: json['vin'] as String?,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
    );
  }
}
