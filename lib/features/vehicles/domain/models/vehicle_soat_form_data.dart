/// Form data object for creating or editing a SOAT on a vehicle.
///
/// This is a lightweight data container used by the vehicle form flow.
/// It is NOT a domain document model — it does not implement
/// [VehicleDocumentModel]. The canonical domain model is [SoatModel] in the
/// `soat` feature.
class VehicleSoatFormData {
  const VehicleSoatFormData({
    this.id,
    required this.vehicleId,
    this.policyNumber,
    required this.startDate,
    required this.expiryDate,
    required this.insurer,
    this.documentUrl,
  });

  final String? id;
  final String vehicleId;
  final String? policyNumber;
  final DateTime startDate;
  final DateTime expiryDate;
  final String insurer;
  final String? documentUrl;
}
