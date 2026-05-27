import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventDetailOwnerMenuButton extends StatelessWidget {
  const EventDetailOwnerMenuButton({
    super.key,
    required this.onEdit,
    required this.onAttendees,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onAttendees;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.darkCard,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkBgPrimary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.more_vert, color: AppColors.textOnDarkPrimary, size: 20),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'attendees':
            onAttendees();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_outlined, color: AppColors.textOnDarkPrimary),
            const SizedBox(width: 12),
            Text(context.l10n.event_edit,
                style: const TextStyle(color: AppColors.textOnDarkPrimary)),
          ]),
        ),
        PopupMenuItem(
          value: 'attendees',
          child: Row(children: [
            const Icon(Icons.people_outline,
                color: AppColors.textOnDarkPrimary),
            const SizedBox(width: 12),
            Text(context.l10n.event_viewAttendees,
                style: const TextStyle(color: AppColors.textOnDarkPrimary)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Text(context.l10n.event_delete,
                style: const TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
    );
  }
}
