import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenanceDetailHeader extends StatelessWidget {
  const MaintenanceDetailHeader({
    super.key,
    required this.maintenance,
    this.vehicle,
  });

  final MaintenanceModel maintenance;
  final VehicleModel? vehicle;

  static IconData _iconForType(MaintenanceType type) => switch (type) {
    MaintenanceType.oilChange => Icons.opacity,
    MaintenanceType.brakeCheck => Icons.album_outlined,
    MaintenanceType.tireChange => Icons.radio_button_unchecked,
    MaintenanceType.preventive => Icons.assignment_turned_in_outlined,
    MaintenanceType.airFilter => Icons.air,
    MaintenanceType.chainSprocket => Icons.link,
    MaintenanceType.electrical => Icons.bolt,
    MaintenanceType.other => Icons.more_horiz,
  };

  String _vehicleDisplayName() {
    if (vehicle == null) return '';
    final parts = [
      vehicle!.brand,
      vehicle!.model,
    ].where((e) => e != null && e.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : vehicle!.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconForType(maintenance.type),
            size: 36,
            color: theme.colorScheme.primary,
          ),
        ),
        AppSpacing.hGapLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                maintenance.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              AppSpacing.gapXxs,
              Text(
                maintenance.mode == MaintenanceMode.completed
                    ? context.l10n.maintenance_performedOn(
                        (maintenance.serviceDate ??
                                maintenance.createdDate ??
                                DateTime.now())
                            .formattedDate,
                      )
                    : context.l10n.maintenance_modeScheduled,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapMd,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DetailPill(
                    leading: Icon(
                      Icons.build_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: context.l10n.maintenance_routine.toUpperCase(),
                    variant: DetailPillVariant.primary,
                  ),
                  if (_vehicleDisplayName().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.two_wheeler,
                            size: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                          AppSpacing.hGapXs,
                          Text(
                            _vehicleDisplayName().toUpperCase(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
