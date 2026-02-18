import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart';

class MaintenancesList extends StatelessWidget {
  final List<MaintenanceModel> maintenances;
  final Future<void> Function(MaintenanceModel) onTap;
  final Future<void> Function(MaintenanceModel) onEdit;
  final void Function(MaintenanceModel) onDelete;

  const MaintenancesList({
    super.key,
    required this.maintenances,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: maintenances.length,
      itemBuilder: (context, index) {
        final maintenance = maintenances[index];
        return ModernMaintenanceCard(
          maintenance: maintenance,
          onTap: () => onTap(maintenance),
          onEdit: () => onEdit(maintenance),
          onDelete: () => onDelete(maintenance),
        );
      },
    );
  }
}
