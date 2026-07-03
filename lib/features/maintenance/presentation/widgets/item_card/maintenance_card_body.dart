import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/design_system/design_system.dart';

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
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);
    final numberFormat = NumberFormat('#,###');

    // Determine urgency color for left border
    final urgencyColor = isUrgent
        ? AppColors.maintenanceUrgent
        : (daysUntilNext != null && daysUntilNext! < 30
              ? AppColors.maintenanceWarning
              : AppColors.maintenanceOk);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: urgencyColor, width: 3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.darkTertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color: context.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  AppSpacing.hGapLg,

                  // Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              maintenance.name,
                              style: context.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (maintenance.cost != null) ...[
                              const Spacer(),
                              Text(
                                currencyFormat.format(maintenance.cost),
                                style: context.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        AppSpacing.gapXxs,
                        Text(
                          (maintenance.serviceDate ??
                                  maintenance.createdDate ??
                                  DateTime.now())
                              .formattedDate,
                          style: context.bodyMedium?.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        if (maintenance.odometerAtService != null) ...[
                          AppSpacing.gapMd,
                          Row(
                            children: [
                              Icon(
                                Icons.speed_outlined,
                                size: 16,
                                color: context.colorScheme.primary,
                              ),
                              AppSpacing.hGapXxs,
                              Text(
                                '${numberFormat.format(maintenance.odometerAtService)} km',
                                style: context.bodySmall?.copyWith(
                                  color: AppColors.darkTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
