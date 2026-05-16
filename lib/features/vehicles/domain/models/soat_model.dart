class SoatModel {
  final String? id;
  final String vehicleId;
  final String policyNumber;
  final DateTime startDate;
  final DateTime expiryDate;
  final String insurer;
  final String? documentUrl;

  const SoatModel({
    this.id,
    required this.vehicleId,
    required this.policyNumber,
    required this.startDate,
    required this.expiryDate,
    required this.insurer,
    this.documentUrl,
  });
}
