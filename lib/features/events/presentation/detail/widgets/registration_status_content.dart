import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/registration_status_chip.dart';

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
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text(EventStrings.editRegistration),
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
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            label: const Text(EventStrings.cancelRegistration),
          ),
        ],
      ],
    );
  }
}
