import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';

class EventCardHeader extends StatelessWidget {
  final String eventName;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCardHeader({
    super.key,
    required this.eventName,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            eventName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOwner) _buildPopupMenu(),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: 8),
              Text(EventStrings.edit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                EventStrings.delete,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
