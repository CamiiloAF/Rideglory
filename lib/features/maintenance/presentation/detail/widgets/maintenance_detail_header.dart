import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
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

  static IconData _iconForType(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Icons.oil_barrel_outlined;
      case MaintenanceType.preventive:
        return Icons.handyman_outlined;
    }
  }

  String _vehicleDisplayName() {
    if (vehicle == null) return '';
    final parts = [vehicle!.brand, vehicle!.model].where((e) => e != null && e.isNotEmpty);
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
        SizedBox(width: 16),
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
              SizedBox(height: 4),
              Text(
                context.l10n.maintenance_performedOn(
                  DateFormat('dd MMM, yyyy').format(maintenance.date),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.8),
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
                          SizedBox(width: 6),
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
