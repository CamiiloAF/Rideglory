import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
        if (isOwner) _buildPopupMenu(context),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
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
              AppSpacing.hGapSm,
              Text(context.l10n.event_edit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: context.colorScheme.error),
              AppSpacing.hGapSm,
              Text(
                context.l10n.event_delete,
                style: TextStyle(color: context.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
