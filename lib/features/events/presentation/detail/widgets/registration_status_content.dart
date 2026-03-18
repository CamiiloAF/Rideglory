import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class RegistrationStatusContent extends StatelessWidget {
  final RegistrationStatus status;
  final String description;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;

  const RegistrationStatusContent({
    super.key,
    required this.status,
    required this.description,
    this.onCancel,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [RegistrationStatusChip(status: status)]),
        AppSpacing.gapSm,
        Text(description, style: theme.textTheme.bodySmall),
        if (onEdit != null || onCancel != null) AppSpacing.gapMd,
        if (onEdit != null)
          AppButton(
            label: context.l10n.event_editRegistration,
            onPressed: onEdit,
            icon: Icons.edit_outlined,
          ),
        if (onCancel != null) ...[
          AppSpacing.gapSm,
          AppTextButton(
            label: context.l10n.event_cancelRegistration,
            onPressed: onCancel,
            icon: Icons.cancel_outlined,
            variant: AppTextButtonVariant.danger,
          ),
        ],
      ],
    );
  }
}
