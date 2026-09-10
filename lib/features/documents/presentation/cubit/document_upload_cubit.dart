import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/services/ocr/ocr_service.dart';
import '../../data/parser/soat_parser.dart';
import '../../data/services/document_reminder_scheduler.dart';
import '../../domain/models/vehicle_document.dart';
import '../../domain/repository/documents_repository.dart';
import '../../domain/usecases/upload_vehicle_document_usecase.dart';
import 'document_upload_state.dart';

/// Subir/reemplazar un documento: origen → (OCR si es SOAT) → confirmar.
///
/// El OCR corre sobre un archivo temporal porque `OcrService` trabaja con
/// `File` (ML Kit no acepta bytes en memoria); si el origen fue un PDF no
/// hay foto que leer y el formulario queda manual directamente.
@injectable
class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  DocumentUploadCubit(
    this._uploadDocument,
    this._ocrService,
    this._soatParser,
    this._reminderScheduler,
  ) : super(const DocumentUploadState(kind: DocumentKind.soat));

  final UploadVehicleDocumentUseCase _uploadDocument;
  final OcrService _ocrService;
  final SoatParser _soatParser;
  final DocumentReminderScheduler _reminderScheduler;

  final TextEditingController numberController = TextEditingController();
  final TextEditingController issuerController = TextEditingController();

  void start(DocumentKind kind) {
    emit(DocumentUploadState(kind: kind));
  }

  Future<void> fileSelected(
    Uint8List bytes,
    String extension, {
    File? imageFileForOcr,
  }) async {
    emit(state.copyWith(fileBytes: bytes, fileExtension: extension));

    if (state.kind == DocumentKind.soat && imageFileForOcr != null) {
      await _runOcr(imageFileForOcr);
    }

    emit(state.copyWith(step: DocumentUploadStep.confirm));
  }

  Future<void> _runOcr(File imageFile) async {
    try {
      final ocrResult = await _ocrService.recognizeText(imageFile);
      final extraction = _soatParser.parse(ocrResult);
      if (!extraction.shouldPrefill) return;

      if (extraction.policyNumber != null)
        numberController.text = extraction.policyNumber!;
      if (extraction.insurer != null)
        issuerController.text = extraction.insurer!;

      emit(
        state.copyWith(
          number: extraction.policyNumber ?? state.number,
          issuer: extraction.insurer ?? state.issuer,
          startDate: extraction.startDate ?? state.startDate,
          expiryDate: extraction.datesFailedValidation
              ? state.expiryDate
              : (extraction.expiryDate ?? state.expiryDate),
          wasAutofilled: true,
        ),
      );
    } catch (_) {
      // El OCR es un prellenado de cortesía: si falla, el formulario sigue
      // manual sin bloquear la subida (regla de producto: nunca falla en
      // silencio algo crítico, y esto no lo es).
    }
  }

  void numberChanged(String value) => emit(state.copyWith(number: value));

  void issuerChanged(String value) => emit(state.copyWith(issuer: value));

  void expiryDateChanged(DateTime date) =>
      emit(state.copyWith(expiryDate: date));

  void backToOrigin() =>
      emit(state.copyWith(step: DocumentUploadStep.origin, fileBytes: null));

  Future<void> submit(
    String vehicleId, {
    required String notificationTitle,
    required String Function(int daysBefore) notificationBodyBuilder,
  }) async {
    final expiryDate = state.expiryDate;
    final fileBytes = state.fileBytes;
    final fileExtension = state.fileExtension;
    if (expiryDate == null || fileBytes == null || fileExtension == null)
      return;

    emit(state.copyWith(submission: const ResultState.loading()));
    final result = await _uploadDocument(
      vehicleId,
      DocumentUploadInput(
        kind: state.kind,
        expiryDate: expiryDate,
        fileBytes: fileBytes,
        fileExtension: fileExtension,
        number: state.number,
        issuer: state.issuer,
        startDate: state.startDate,
      ),
    );

    await result.fold(
      (error) async =>
          emit(state.copyWith(submission: ResultState.error(error: error))),
      (document) async {
        await _reminderScheduler.scheduleForDocument(
          vehicleId,
          document,
          vehicleName: vehicleId,
          title: notificationTitle,
          bodyBuilder: notificationBodyBuilder,
        );
        emit(state.copyWith(submission: const ResultState.data(data: unit)));
      },
    );
  }

  @override
  Future<void> close() {
    numberController.dispose();
    issuerController.dispose();
    return super.close();
  }
}
