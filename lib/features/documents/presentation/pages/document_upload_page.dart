import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle_document.dart';
import '../cubit/document_upload_cubit.dart';
import '../cubit/document_upload_state.dart';
import '../widgets/document_upload_confirm_step.dart';
import '../widgets/document_upload_origin_step.dart';

/// Subir o reemplazar un documento: origen → confirmar.
///
/// Pencil: R9ZYe (origen), rbRuw (cámara), MG790 (confirmar)
class DocumentUploadPage extends StatelessWidget {
  const DocumentUploadPage({required this.vehicleId, required this.kind, super.key});

  final String vehicleId;
  final DocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final title =
        kind == DocumentKind.soat ? context.l10n.documents_soat_title : context.l10n.documents_rtm_title;
    return BlocProvider(
      create: (_) => getIt<DocumentUploadCubit>()..start(kind),
      child: BlocListener<DocumentUploadCubit, DocumentUploadState>(
        listenWhen: (previous, current) => previous.submission != current.submission,
        listener: (context, state) {
          if (state.submission is Data<Unit>) context.pop(true);
        },
        child: Scaffold(
          appBar: AppPageHeader(title: title),
          body: SafeArea(
            child: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
              buildWhen: (previous, current) => previous.step != current.step,
              builder: (context, state) {
                return state.step == DocumentUploadStep.origin
                    ? DocumentUploadOriginStep(vehicleId: vehicleId)
                    : DocumentUploadConfirmStep(vehicleId: vehicleId);
              },
            ),
          ),
        ),
      ),
    );
  }
}
