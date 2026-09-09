import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/models/vehicle_document.dart';
import 'pages/document_upload_page.dart';
import 'pages/document_viewer_page.dart';

/// Rutas de documentos anidadas bajo `/garage`, registradas con una línea
/// en `app_router.dart`.
List<RouteBase> documentsRoutes = [
  GoRoute(
    path: AppRoutes.documentViewerPath,
    name: AppRoutes.documentViewer,
    builder: (context, state) => DocumentViewerPage(
      vehicleId: state.extra! as String,
      kind: _kindFrom(state.pathParameters['kind']),
    ),
  ),
  GoRoute(
    path: AppRoutes.documentUploadPath,
    name: AppRoutes.documentUpload,
    builder: (context, state) => DocumentUploadPage(
      vehicleId: state.extra! as String,
      kind: _kindFrom(state.pathParameters['kind']),
    ),
  ),
];

DocumentKind _kindFrom(String? raw) => raw == 'rtm' ? DocumentKind.rtm : DocumentKind.soat;
