import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenanceCardActionsMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MaintenanceCardActionsMenu({super.key, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 20),
                AppSpacing.hGapMd,
                Text(context.l10n.edit),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                AppSpacing.hGapMd,
                Text(context.l10n.delete, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          ConfirmationDialog.show(
            context: context,
            title: context.l10n.maintenance_deleteMaintenance,
            content: context.l10n.maintenance_deleteMaintenanceMessage,
            cancelLabel: context.l10n.cancel,
            confirmLabel: context.l10n.delete,
            confirmType: DialogActionType.danger,
            dialogType: DialogType.warning,
            onConfirm: () => onDelete?.call(),
          );
        }
      },
    );
  }
}
