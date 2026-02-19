import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/item_card.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_card_actions_menu.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/vehicle_info_chip.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class MaintenanceCardBody extends StatelessWidget {
  final MaintenanceModel maintenance;
  final VehicleModel? maintenanceVehicle;
  final Color typeColor;
  final IconData typeIcon;
  final int? currentMileage;
  final double? progressPercent;
  final bool isUrgent;
  final int? daysUntilNext;
  final int? Function(int?) getRemainingDistance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MaintenanceCardBody({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, typeColor.withValues(alpha: 0.05)],
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MaintenanceCardHeader(
                          maintenance: maintenance,
                          typeColor: typeColor,
                          typeIcon: typeIcon,
                          isUrgent: isUrgent,
                        ),
                      ),
                      if (onEdit != null || onDelete != null)
                        MaintenanceCardActionsMenu(
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                    ],
                  ),
                  if (maintenanceVehicle != null) ...[
                    const SizedBox(height: 12),
                    VehicleInfoChip(vehicle: maintenanceVehicle!),
                  ],
                  const SizedBox(height: 20),
                  MaintenanceMileageInfo(
                    maintenance: maintenance,
                    typeColor: typeColor,
                    currentMileage: currentMileage,
                    progressPercent: progressPercent,
                    getRemainingDistance: getRemainingDistance,
                  ),
                  const SizedBox(height: 16),
                  MaintenanceDatesSection(
                    maintenance: maintenance,
                    daysUntilNext: daysUntilNext,
                  ),
                  if (maintenance.notes != null &&
                      maintenance.notes!.isNotEmpty)
                    MaintenanceNotesSection(maintenance: maintenance),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
