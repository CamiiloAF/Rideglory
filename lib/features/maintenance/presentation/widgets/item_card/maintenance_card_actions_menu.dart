import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

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
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20),
                SizedBox(width: 12),
                Text(AppStrings.edit),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
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
            title: MaintenanceStrings.deleteMaintenance,
            content: MaintenanceStrings.deleteMaintenanceMessage,
            cancelLabel: AppStrings.cancel,
            confirmLabel: AppStrings.delete,
            confirmType: DialogActionType.danger,
            dialogType: DialogType.warning,
            onConfirm: () => onDelete?.call(),
          );
        }
      },
    );
  }
}
