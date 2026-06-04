import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_expiry.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';

export 'package:rideglory/features/vehicle_documents/domain/vehicle_document_kind.dart';
export 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';

/// Base contract for all vehicle legal documents (SOAT, RTM, etc.).
///
/// Implementors must also use the [VehicleDocumentExpiry] mixin, which
/// provides [daysUntilExpiry] and [documentStatus].
abstract class VehicleDocumentModel with VehicleDocumentExpiry {
  String get id;
  String get vehicleId;

  @override
  DateTime get expiryDate;

  @override
  int get daysUntilExpiry;

  @override
  VehicleDocumentStatus get documentStatus;
}
