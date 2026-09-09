import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle_document.dart';
import '../models/vehicle_documents_summary.dart';

/// Datos para subir o reemplazar un documento. El archivo es obligatorio;
/// los demás campos dependen de si el OCR pudo prellenarlos.
class DocumentUploadInput {
  const DocumentUploadInput({
    required this.kind,
    required this.expiryDate,
    required this.fileBytes,
    required this.fileExtension,
    this.number,
    this.issuer,
    this.startDate,
  });

  final DocumentKind kind;
  final DateTime expiryDate;
  final Uint8List fileBytes;
  final String fileExtension;
  final String? number;
  final String? issuer;
  final DateTime? startDate;
}

abstract class DocumentsRepository {
  Future<Either<DomainException, VehicleDocumentsSummary>> getDocuments(String vehicleId);

  Future<Either<DomainException, VehicleDocument>> uploadDocument(
    String vehicleId,
    DocumentUploadInput input,
  );

  Future<Either<DomainException, Unit>> deleteDocument(String vehicleId, DocumentKind kind);

  Future<Either<DomainException, Unit>> setReminderEnabled(
    String vehicleId,
    DocumentKind kind,
    bool enabled,
  );

  /// Bytes del archivo, para el visor: primero intenta la caché local
  /// (D7); si no existe y hay red, lo descarga y lo cachea.
  Future<Either<DomainException, Uint8List>> getDocumentBytes(String vehicleId, DocumentKind kind);
}
