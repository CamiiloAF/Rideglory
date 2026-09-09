import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/saving_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/document_upload_cubit.dart';
import '../cubit/document_upload_state.dart';

/// "Guardar documento", con sus tres estados.
///
/// Pencil: MG790, error análogo a `sH7QQ`
class DocumentUploadSubmitButton extends StatelessWidget {
  const DocumentUploadSubmitButton({required this.vehicleId, super.key});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentUploadCubit>();
    return BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.submission is Error<Unit>) ...[
              AppBanner(
                title: context.l10n.documents_save_error_title,
                body: context.l10n.documents_save_error_body,
              ),
              const SizedBox(height: 12),
            ],
            if (state.submission is Loading<Unit>)
              SavingButton(label: context.l10n.documents_saving_label)
            else
              AppPrimaryButton(
                label: context.l10n.documents_save_button,
                onPressed: state.canSave
                    ? () => cubit.submit(
                          vehicleId,
                          notificationTitle: state.kind.name == 'soat'
                              ? context.l10n.documents_soat_title
                              : context.l10n.documents_rtm_title,
                          notificationBodyBuilder: (daysBefore) =>
                              context.l10n.documents_reminder_body(daysBefore),
                        )
                    : null,
              ),
          ],
        );
      },
    );
  }
}
