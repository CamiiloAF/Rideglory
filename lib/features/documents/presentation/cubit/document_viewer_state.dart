import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_viewer_state.freezed.dart';

/// El visor tiene tres desenlaces propios además de carga/error genéricos:
/// contenido (con o sin red), sin subir y sin conexión sin copia local.
@freezed
class DocumentViewerState with _$DocumentViewerState {
  const factory DocumentViewerState.loading() = DocumentViewerLoading;

  const factory DocumentViewerState.loaded({required Uint8List bytes, required bool isOffline}) =
      DocumentViewerLoaded;

  const factory DocumentViewerState.notUploaded() = DocumentViewerNotUploaded;

  const factory DocumentViewerState.offlineNoCache() = DocumentViewerOfflineNoCache;

  const factory DocumentViewerState.error() = DocumentViewerError;
}
