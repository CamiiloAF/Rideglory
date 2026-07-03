import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';

/// Mixin for domain models that have an expiry date.
///
/// Implementors must expose [expiryDate]. The mixin derives [daysUntilExpiry]
/// and [documentStatus] without any Flutter dependency.
mixin VehicleDocumentExpiry {
  DateTime get expiryDate;

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  VehicleDocumentStatus get documentStatus {
    final days = daysUntilExpiry;
    if (days < 0) return VehicleDocumentStatus.expired;
    if (days <= 30) return VehicleDocumentStatus.expiringSoon;
    return VehicleDocumentStatus.valid;
  }
}
