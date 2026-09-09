import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle_document.dart';
import '../cubit/document_upload_cubit.dart';
import '../cubit/document_upload_state.dart';
import 'document_preview_frame.dart';
import 'document_upload_soat_fields.dart';
import 'document_upload_submit_button.dart';
import 'expiry_date_field.dart';

/// "¿Se ve completo y legible?": vista previa, campos (número/aseguradora
/// para SOAT) y la fecha de vencimiento.
///
/// Pencil: MG790
class DocumentUploadConfirmStep extends StatelessWidget {
  const DocumentUploadConfirmStep({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentUploadCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.documents_confirm_question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 260,
                child: state.fileBytes == null
                    ? const SizedBox.shrink()
                    : DocumentPreviewFrame(bytes: state.fileBytes!),
              ),
              const SizedBox(height: 14),
              if (state.kind == DocumentKind.soat) ...[
                const DocumentUploadSoatFields(),
                const SizedBox(height: 14),
              ],
              const ExpiryDateField(),
              const SizedBox(height: 24),
              DocumentUploadSubmitButton(vehicleId: vehicleId),
              const SizedBox(height: 10),
              TextButton(
                onPressed: cubit.backToOrigin,
                child: Text(context.l10n.documents_retake_button),
              ),
            ],
          );
        },
      ),
    );
  }
}
