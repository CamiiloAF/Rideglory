import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/repository/documents_repository_impl.dart';
import '../../domain/models/vehicle_document.dart';
import '../../domain/usecases/get_document_bytes_usecase.dart';
import 'document_viewer_state.dart';

/// Visor de un documento: copia local primero (D7), y si no hay copia y no
/// hay red, el estado propio `offlineNoCache` en vez de un error genérico.
@injectable
class DocumentViewerCubit extends Cubit<DocumentViewerState> {
  DocumentViewerCubit(this._getDocumentBytes, this._connectivity)
      : super(const DocumentViewerState.loading());

  final GetDocumentBytesUseCase _getDocumentBytes;
  final Connectivity _connectivity;

  Future<void> load(String vehicleId, DocumentKind kind) async {
    emit(const DocumentViewerState.loading());
    final results = await _connectivity.checkConnectivity();
    final isOffline = results.isEmpty || results.every((result) => result == ConnectivityResult.none);

    final result = await _getDocumentBytes(vehicleId, kind);
    result.fold(
      (error) {
        if (error.message == DocumentsRepositoryImpl.offlineNoCacheMessage) {
          emit(const DocumentViewerState.offlineNoCache());
        } else if (error.message == DocumentsRepositoryImpl.notFoundMessage) {
          emit(const DocumentViewerState.notUploaded());
        } else {
          emit(const DocumentViewerState.error());
        }
      },
      (bytes) => emit(DocumentViewerState.loaded(bytes: bytes, isOffline: isOffline)),
    );
  }
}
