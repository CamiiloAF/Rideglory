import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_expiry.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_model.dart';

class TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel {
  const TecnomecanicaModel({
    required this.id,
    required this.vehicleId,
    required this.certificateNumber,
    required this.cdaName,
    this.cdaCode,
    this.startDate,
    required this.expiryDate,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String vehicleId;
  final String certificateNumber;
  final String cdaName;
  final String? cdaCode;
  final DateTime? startDate;
  @override
  final DateTime expiryDate;
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleDocumentKind get kind => VehicleDocumentKind.rtm;

  // daysUntilExpiry + documentStatus come from VehicleDocumentExpiry mixin

  TecnomecanicaModel copyWith({
    String? id,
    String? vehicleId,
    String? certificateNumber,
    String? cdaName,
    String? cdaCode,
    DateTime? startDate,
    DateTime? expiryDate,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TecnomecanicaModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      cdaName: cdaName ?? this.cdaName,
      cdaCode: cdaCode ?? this.cdaCode,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      documentUrl: documentUrl ?? this.documentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TecnomecanicaModel &&
            id == other.id &&
            vehicleId == other.vehicleId &&
            certificateNumber == other.certificateNumber &&
            cdaName == other.cdaName &&
            cdaCode == other.cdaCode &&
            startDate == other.startDate &&
            expiryDate == other.expiryDate &&
            documentUrl == other.documentUrl;
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    certificateNumber,
    cdaName,
    cdaCode,
    startDate,
    expiryDate,
    documentUrl,
  );
}
