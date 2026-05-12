class VehicleSummaryModel {
  const VehicleSummaryModel({
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

  String get displayName {
    final parts = <String>[
      if (brand != null && brand!.trim().isNotEmpty) brand!.trim(),
      if (model != null && model!.trim().isNotEmpty) model!.trim(),
    ];
    return parts.join(' ').trim();
  }
}
