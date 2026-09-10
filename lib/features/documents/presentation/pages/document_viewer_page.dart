import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle_document.dart';
import '../cubit/document_viewer_cubit.dart';
import '../cubit/document_viewer_state.dart';
import '../widgets/document_viewer_body.dart';

/// Visor de un documento (SOAT o RTM): copia local primero, `Compartir` y
/// `Reemplazar documento`.
///
/// Pencil: tu2U6 (con red), P5GIm (sin conexión), dB4Au (sin subir)
class DocumentViewerPage extends StatelessWidget {
  const DocumentViewerPage({
    required this.vehicleId,
    required this.kind,
    super.key,
  });

  final String vehicleId;
  final DocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final title = kind == DocumentKind.soat
        ? context.l10n.documents_soat_title
        : context.l10n.documents_rtm_title;
    return BlocProvider(
      create: (_) => getIt<DocumentViewerCubit>()..load(vehicleId, kind),
      child: Scaffold(
        appBar: AppPageHeader(title: title),
        body: SafeArea(
          child: BlocBuilder<DocumentViewerCubit, DocumentViewerState>(
            builder: (context, state) {
              return DocumentViewerBody(
                state: state,
                vehicleId: vehicleId,
                kind: kind,
                onRetry: () =>
                    context.read<DocumentViewerCubit>().load(vehicleId, kind),
              );
            },
          ),
        ),
      ),
    );
  }
}
