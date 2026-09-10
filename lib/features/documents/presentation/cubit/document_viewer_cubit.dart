import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/repository/documents_repository_impl.dart';
import '../../data/services/document_reminder_scheduler.dart';
import '../../domain/models/vehicle_document.dart';
import '../../domain/usecases/get_document_bytes_usecase.dart';
import '../../domain/usecases/get_vehicle_documents_usecase.dart';
import '../../domain/usecases/toggle_document_reminder_usecase.dart';
import 'document_viewer_state.dart';

/// Visor de un documento: copia local primero (D7), y si no hay copia y no
/// hay red, el estado propio `offlineNoCache` en vez de un error genérico.
/// También gestiona el recordatorio de vencimiento (D6): el toggle se
/// persiste y programa/cancela la notificación local correspondiente.
@injectable
class DocumentViewerCubit extends Cubit<DocumentViewerState> {
  DocumentViewerCubit(
    this._getDocumentBytes,
    this._getDocuments,
    this._toggleReminder,
    this._reminderScheduler,
    this._connectivity,
  ) : super(const DocumentViewerState.loading());

  final GetDocumentBytesUseCase _getDocumentBytes;
  final GetVehicleDocumentsUseCase _getDocuments;
  final ToggleDocumentReminderUseCase _toggleReminder;
  final DocumentReminderScheduler _reminderScheduler;
  final Connectivity _connectivity;

  Future<void> load(String vehicleId, DocumentKind kind) async {
    emit(const DocumentViewerState.loading());
    final results = await _connectivity.checkConnectivity();
    final isOffline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);

    final bytesResult = await _getDocumentBytes(vehicleId, kind);
    await bytesResult.fold(
      (error) async {
        if (error.message == DocumentsRepositoryImpl.offlineNoCacheMessage) {
          emit(const DocumentViewerState.offlineNoCache());
        } else if (error.message == DocumentsRepositoryImpl.notFoundMessage) {
          emit(const DocumentViewerState.notUploaded());
        } else {
          emit(const DocumentViewerState.error());
        }
      },
      (bytes) async {
        final summaryResult = await _getDocuments(vehicleId);
        summaryResult.fold((error) => emit(const DocumentViewerState.error()), (
          summary,
        ) {
          final document = kind == DocumentKind.soat
              ? summary.soat
              : summary.rtm;
          if (document == null) {
            emit(const DocumentViewerState.notUploaded());
            return;
          }
          emit(
            DocumentViewerState.loaded(
              bytes: bytes,
              isOffline: isOffline,
              document: document,
            ),
          );
        });
      },
    );
  }

  /// Persiste la preferencia y programa/cancela la notificación local. No
  /// pide el permiso del sistema aquí: la presentación debe pasar por
  /// `NotificationPermissionSheet` antes de llamar a esto cuando se activa.
  Future<void> setReminderEnabled(
    String vehicleId, {
    required bool enabled,
    required String vehicleName,
    required String title,
    required String Function(int daysBefore) bodyBuilder,
  }) async {
    final currentState = state;
    if (currentState is! DocumentViewerLoaded) return;
    final document = currentState.document;

    final result = await _toggleReminder(vehicleId, document.kind, enabled);
    result.fold((error) => null, (_) async {
      final updatedDocument = document.copyWith(reminderEnabled: enabled);
      if (enabled) {
        await _reminderScheduler.scheduleForDocument(
          vehicleId,
          updatedDocument,
          vehicleName: vehicleName,
          title: title,
          bodyBuilder: bodyBuilder,
        );
      } else {
        await _reminderScheduler.cancelForDocument(vehicleId, document.kind);
      }
      emit(currentState.copyWith(document: updatedDocument));
    });
  }
}
