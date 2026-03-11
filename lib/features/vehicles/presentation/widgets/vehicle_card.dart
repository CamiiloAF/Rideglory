import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/shared/widgets/info_chip.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAddMaintenance;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final bool isCurrent;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onDelete,
    this.onAddMaintenance,
    this.onArchive,
    this.onUnarchive,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Image or Placeholder
                    ClipOval(
                      child: Container(
                        width: 56,
                        height: 56,
                        color: AppColors.darkSurfaceHighest,
                        child:
                            vehicle.imageUrl != null &&
                                vehicle.imageUrl!.isNotEmpty
                            ? Image.network(
                                vehicle.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderIcon(),
                              )
                            : _buildPlaceholderIcon(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicle.name,
                                  style: context.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (vehicle.isArchived)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurfaceHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.archive_outlined,
                                        size: 12,
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Archivado',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: context
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (vehicle.brand != null ||
                              vehicle.model != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              [
                                vehicle.brand,
                                vehicle.model,
                              ].where((e) => e != null).join(' '),
                              style: context.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onDelete != null || onAddMaintenance != null)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        color: AppColors.darkSurfaceHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.darkBorder),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: context.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.edit,
                                  style: TextStyle(
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onAddMaintenance != null)
                            PopupMenuItem(
                              value: 'addMaintenance',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.build_circle_outlined,
                                    size: 20,
                                    color: context.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    MaintenanceStrings.addMaintenanceAction,
                                    style: TextStyle(
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!vehicle.isArchived && onArchive != null)
                            PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.archive_outlined,
                                    size: 20,
                                    color: context.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    VehicleStrings.archiveVehicle,
                                    style: TextStyle(
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (vehicle.isArchived && onUnarchive != null)
                            PopupMenuItem(
                              value: 'unarchive',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.unarchive_outlined,
                                    size: 20,
                                    color: context.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    VehicleStrings.unarchiveVehicle,
                                    style: TextStyle(
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: context.colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.delete,
                                  style: TextStyle(
                                    color: context.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit' && onTap != null) {
                            onTap!();
                          } else if (value == 'addMaintenance' &&
                              onAddMaintenance != null) {
                            onAddMaintenance!();
                          } else if (value == 'archive' && onArchive != null) {
                            onArchive!();
                          } else if (value == 'unarchive' &&
                              onUnarchive != null) {
                            onUnarchive!();
                          } else if (value == 'delete') {
                            onDelete!();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info chips section
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      icon: Icons.speed_rounded,
                      label:
                          '${vehicle.currentMileage} ${vehicle.distanceUnit.label}',
                      color: AppColors.primary,
                    ),
                    if (vehicle.year != null)
                      InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: vehicle.year.toString(),
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    if (vehicle.licensePlate != null)
                      InfoChip(
                        icon: Icons.badge_rounded,
                        label: vehicle.licensePlate!,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      vehicle.vehicleType == VehicleType.motorcycle
          ? Icons.two_wheeler_rounded
          : Icons.directions_car_rounded,
      color: AppColors.primary,
      size: 28,
    );
  }
}
