import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/document_upload_cubit.dart';
import '../cubit/document_upload_state.dart';

/// "¿Cuándo vence?": selector de fecha, nunca texto libre (evita fechas
/// imposibles que romperían el recordatorio local).
///
/// Pencil: MG790 › Campo Vence
class ExpiryDateField extends StatelessWidget {
  const ExpiryDateField({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<DocumentUploadCubit>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cubit.state.expiryDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) cubit.expiryDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
      buildWhen: (previous, current) => previous.expiryDate != current.expiryDate,
      builder: (context, state) {
        final expiryDate = state.expiryDate;
        return AppTextField(
          label: context.l10n.documents_expiry_date_label,
          controller: TextEditingController(
            text: expiryDate == null ? '' : DateFormat('d MMM yyyy', 'es_CO').format(expiryDate),
          ),
          icon: LucideIcons.calendar,
          readOnly: true,
          onTap: () => _pickDate(context),
          helperText: context.l10n.documents_expiry_date_helper,
        );
      },
    );
  }
}
