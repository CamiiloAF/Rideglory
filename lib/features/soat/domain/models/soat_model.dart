import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_expiry.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_model.dart';

enum SoatStatus { noSoat, valid, expiringSoon, expired }

class SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel {
  const SoatModel({
    required this.id,
    required this.vehicleId,
    this.policyNumber,
    this.startDate,
    required this.expiryDate,
    this.insurer,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String vehicleId;
  final String? policyNumber;
  final DateTime? startDate;
  @override
  final DateTime expiryDate;
  final String? insurer;
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleDocumentKind get kind => VehicleDocumentKind.soat;

  /// Maps [documentStatus] (from the [VehicleDocumentExpiry] mixin) to the
  /// legacy [SoatStatus] enum consumed by existing widgets, router, and analytics.
  SoatStatus get status {
    return switch (documentStatus) {
      VehicleDocumentStatus.expired => SoatStatus.expired,
      VehicleDocumentStatus.expiringSoon => SoatStatus.expiringSoon,
      VehicleDocumentStatus.valid => SoatStatus.valid,
      VehicleDocumentStatus.none => SoatStatus.noSoat,
    };
  }

  SoatModel copyWith({
    String? id,
    String? vehicleId,
    String? policyNumber,
    DateTime? startDate,
    DateTime? expiryDate,
    String? insurer,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoatModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      policyNumber: policyNumber ?? this.policyNumber,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      insurer: insurer ?? this.insurer,
      documentUrl: documentUrl ?? this.documentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SoatModel &&
            id == other.id &&
            vehicleId == other.vehicleId &&
            policyNumber == other.policyNumber &&
            startDate == other.startDate &&
            expiryDate == other.expiryDate &&
            insurer == other.insurer &&
            documentUrl == other.documentUrl;
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    policyNumber,
    startDate,
    expiryDate,
    insurer,
    documentUrl,
  );
}
