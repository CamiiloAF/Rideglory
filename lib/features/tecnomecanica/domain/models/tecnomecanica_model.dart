import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_expiry.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_model.dart';

class TecnomecanicaModel
    with VehicleDocumentExpiry
    implements VehicleDocumentModel {
  const TecnomecanicaModel({
    required this.id,
    required this.vehicleId,
    required this.cdaName,
    required this.startDate,
    required this.expiryDate,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
  });

  @override
  final String id;
  @override
  final String vehicleId;
  final String cdaName;
  @override
  final DateTime expiryDate;
  final DateTime startDate;
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleDocumentKind get kind => VehicleDocumentKind.rtm;

  TecnomecanicaModel copyWith({
    String? id,
    String? vehicleId,
    String? cdaName,
    DateTime? startDate,
    DateTime? expiryDate,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TecnomecanicaModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      cdaName: cdaName ?? this.cdaName,
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
            cdaName == other.cdaName &&
            startDate == other.startDate &&
            expiryDate == other.expiryDate &&
            documentUrl == other.documentUrl;
  }

  @override
  int get hashCode =>
      Object.hash(id, vehicleId, cdaName, startDate, expiryDate, documentUrl);
}
