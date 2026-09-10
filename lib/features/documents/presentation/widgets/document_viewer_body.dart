import 'package:flutter/material.dart';

import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/offline_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../../domain/models/vehicle_document.dart';
import '../cubit/document_viewer_state.dart';
import 'document_not_uploaded_view.dart';
import 'document_viewer_content.dart';

/// Mapea el [DocumentViewerState] a sus vistas: carga, sin subir, sin
/// conexión sin copia, error o el contenido con `Compartir`/`Reemplazar`.
class DocumentViewerBody extends StatelessWidget {
  const DocumentViewerBody({
    required this.state,
    required this.vehicleId,
    required this.kind,
    required this.onRetry,
    super.key,
  });

  final DocumentViewerState state;
  final String vehicleId;
  final DocumentKind kind;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const SkeletonList(itemCount: 3, itemHeight: 100),
      notUploaded: () => DocumentNotUploadedView(vehicleId: vehicleId, kind: kind),
      offlineNoCache: () => OfflineStateView(onRetry: onRetry),
      error: () => ErrorStateView(onRetry: onRetry),
      loaded: (bytes, isOffline, document) => DocumentViewerContent(
        bytes: bytes,
        isOffline: isOffline,
        document: document,
        vehicleId: vehicleId,
        kind: kind,
      ),
    );
  }
}
