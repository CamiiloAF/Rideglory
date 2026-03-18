import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outlineVariant),
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
                        color: context.colorScheme.surfaceContainerHighest,
                        child:
                            vehicle.imageUrl != null &&
                                vehicle.imageUrl!.isNotEmpty
                            ? Image.network(
                                vehicle.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _buildPlaceholderIcon(context),
                              )
                            : _buildPlaceholderIcon(context),
                      ),
                    ),
                    AppSpacing.hGapMd,
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
                                    color: context
                                        .colorScheme
                                        .surfaceContainerHighest,
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
                                      AppSpacing.hGapXxs,
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
                            AppSpacing.gapXxs,
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
                        color: context.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: context.colorScheme.outlineVariant,
                          ),
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
                                AppSpacing.hGapMd,
                                Text(
                                  context.l10n.edit,
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
                                  AppSpacing.hGapMd,
                                  Text(
                                    context
                                        .l10n
                                        .maintenance_addMaintenanceAction,
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
                                  AppSpacing.hGapMd,
                                  Text(
                                    context.l10n.vehicle_archiveVehicle,
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
                                  AppSpacing.hGapMd,
                                  Text(
                                    context.l10n.vehicle_unarchiveVehicle,
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
                                AppSpacing.hGapMd,
                                Text(
                                  context.l10n.delete,
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
                AppSpacing.gapLg,
                // Info chips section
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      icon: Icons.speed_rounded,
                      label: '${vehicle.currentMileage} km',
                      color: context.colorScheme.primary,
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

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Icon(
      Icons.two_wheeler_rounded,
      color: context.colorScheme.primary,
      size: 28,
    );
  }
}
