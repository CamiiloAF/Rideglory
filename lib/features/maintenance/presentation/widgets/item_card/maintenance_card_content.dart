import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_card_body.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class MaintenanceCardContent extends StatelessWidget {
  final MaintenanceModel maintenance;
  final VehicleModel? maintenanceVehicle;
  final Color typeColor;
  final IconData typeIcon;
  final int? currentMileage;
  final double? progressPercent;
  final bool isUrgent;
  final int? daysUntilNext;
  final double? Function(int?) getRemainingDistance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MaintenanceCardContent({
    super.key,
    required this.maintenance,
    this.maintenanceVehicle,
    required this.typeColor,
    required this.typeIcon,
    required this.currentMileage,
    required this.progressPercent,
    required this.isUrgent,
    required this.daysUntilNext,
    required this.getRemainingDistance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(maintenance.id ?? maintenance.hashCode.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        bool confirmed = false;

        await ConfirmationDialog.show(
          context: context,
          title: MaintenanceStrings.deleteMaintenance,
          content: MaintenanceStrings.deleteMaintenanceMessage,
          cancelLabel: AppStrings.cancel,
          confirmLabel: AppStrings.delete,
          confirmType: DialogActionType.danger,
          dialogType: DialogType.warning,
          onConfirm: () {
            confirmed = true;
            onDelete?.call();
          },
        );

        return confirmed;
      },
      onDismissed: (direction) {
        onDelete?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              AppStrings.delete,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: MaintenanceCardBody(
        maintenance: maintenance,
        maintenanceVehicle: maintenanceVehicle,
        typeColor: typeColor,
        typeIcon: typeIcon,
        currentMileage: currentMileage,
        progressPercent: progressPercent,
        isUrgent: isUrgent,
        daysUntilNext: daysUntilNext,
        getRemainingDistance: getRemainingDistance,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}
