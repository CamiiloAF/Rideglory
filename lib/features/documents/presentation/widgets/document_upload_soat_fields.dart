import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/document_upload_cubit.dart';
import '../cubit/document_upload_state.dart';

/// Número de póliza y aseguradora, solo para SOAT. El OCR puede haberlos
/// prellenado; si no, el rider los escribe a mano.
///
/// Pencil: MG790 (variante SOAT, no capturada en el frame de RTM)
class DocumentUploadSoatFields extends StatelessWidget {
  const DocumentUploadSoatFields({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentUploadCubit>();
    return BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
      buildWhen: (previous, current) =>
          previous.wasAutofilled != current.wasAutofilled,
      builder: (context, state) {
        final helper = state.wasAutofilled
            ? context.l10n.documents_autofilled_hint
            : null;
        return Column(
          children: [
            AppTextField(
              label: context.l10n.documents_policy_number_label,
              controller: cubit.numberController,
              onChanged: cubit.numberChanged,
              helperText: helper,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: context.l10n.documents_issuer_label,
              controller: cubit.issuerController,
              onChanged: cubit.issuerChanged,
            ),
          ],
        );
      },
    );
  }
}
