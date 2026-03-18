import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

enum MaintenanceAction { edit, delete }

class MaintenanceOptionsBottomSheet extends StatelessWidget {
  const MaintenanceOptionsBottomSheet({super.key});

  static Future<MaintenanceAction?> show(BuildContext context) {
    return showModalBottomSheet<MaintenanceAction>(
      context: context,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => const MaintenanceOptionsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.white),
            title: Text(
              context.l10n.maintenance_editMaintenance,
              style: context.bodyLarge?.copyWith(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context, MaintenanceAction.edit);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              context.l10n.maintenance_deleteMaintenance,
              style: context.bodyLarge?.copyWith(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context, MaintenanceAction.delete);
            },
          ),
          AppSpacing.gapLg,
        ],
      ),
    );
  }
}
