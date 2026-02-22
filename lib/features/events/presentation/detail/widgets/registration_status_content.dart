import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';

class RegistrationStatusContent extends StatelessWidget {
  final RegistrationStatus status;
  final String description;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final VoidCallback? onViewRecommendations;

  const RegistrationStatusContent({
    super.key,
    required this.status,
    required this.description,
    this.onCancel,
    this.onEdit,
    this.onViewRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [RegistrationStatusChip(status: status)]),
        const SizedBox(height: 8),
        Text(description, style: theme.textTheme.bodySmall),
        if (onEdit != null || onCancel != null || onViewRecommendations != null)
          const SizedBox(height: 12),
        if (onEdit != null)
          AppButton(
            label: EventStrings.editRegistration,
            onPressed: onEdit,
            icon: Icons.edit_outlined,
          ),
        if (onViewRecommendations != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onViewRecommendations,
            icon: const Icon(Icons.tips_and_updates_outlined),
            label: const Text(EventStrings.viewRecommendations),
          ),
        ],
        if (onCancel != null) ...[
          const SizedBox(height: 8),
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
