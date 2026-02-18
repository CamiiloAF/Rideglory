import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';

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
                Text('Editar'),
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
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
      onSelected: (value) async {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          final confirm = await AppDialogHelper.showConfirmation(
            context: context,
            title: 'Eliminar mantenimiento',
            content:
                '¿Estás seguro de que deseas eliminar este mantenimiento? Esta acción no se puede deshacer.',
            cancelLabel: 'Cancelar',
            confirmLabel: 'Eliminar',
            confirmType: DialogActionType.danger,
            dialogType: DialogType.warning,
          );
          if (confirm == true) {
            onDelete?.call();
          }
        }
      },
    );
  }
}
