import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/design_system/design_system.dart';

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
        SizedBox(height: 8),
        Text(description, style: theme.textTheme.bodySmall),
        if (onEdit != null || onCancel != null) SizedBox(height: 12),
        if (onEdit != null)
          AppButton(
            label: EventStrings.editRegistration,
            onPressed: onEdit,
            icon: Icons.edit_outlined,
          ),
        if (onCancel != null) ...[
          SizedBox(height: 8),
          AppTextButton(
            label: EventStrings.cancelRegistration,
            onPressed: onCancel,
            icon: Icons.cancel_outlined,
            variant: AppTextButtonVariant.danger,
          ),
        ],
      ],
    );
  }
}
