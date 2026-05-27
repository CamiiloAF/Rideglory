import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventCardPopupMenu extends StatelessWidget {
  const EventCardPopupMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
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
