import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/models/vehicle_document.dart';

part 'document_upload_state.freezed.dart';

enum DocumentUploadStep { origin, confirm }

/// Estado del flujo de subida (origen → confirmar). Un único resultado
/// asíncrono (guardar), así que un `ResultState<Unit>` dentro de esta clase
/// alcanza sin necesitar un `ResultState` por campo.
@freezed
abstract class DocumentUploadState with _$DocumentUploadState {
  const factory DocumentUploadState({
    required DocumentKind kind,
    @Default(DocumentUploadStep.origin) DocumentUploadStep step,
    Uint8List? fileBytes,
    String? fileExtension,
    String? number,
    String? issuer,
    DateTime? startDate,
    DateTime? expiryDate,
    @Default(false) bool wasAutofilled,
    @Default(ResultState<Unit>.initial()) ResultState<Unit> submission,
  }) = _DocumentUploadState;

  const DocumentUploadState._();

  bool get canSave => expiryDate != null && fileBytes != null;
}
