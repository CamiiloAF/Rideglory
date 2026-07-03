import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/maintenance_type_style.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class _BadgeStyle {
  const _BadgeStyle({
    required this.color,
    required this.background,
    required this.label,
  });
  final Color color;
  final Color background;
  final String label;
}

class MaintenanceTypeCard extends StatelessWidget {
  final MaintenanceModel maintenance;
  final VehicleModel? vehicle;

  const MaintenanceTypeCard({
    super.key,
    required this.maintenance,
    this.vehicle,
  });

  static const _successColor = AppColors.statusGreen;
  static const _successSubtle = Color(
    0x1A22C55E,
  ); // Intentional: alpha variant of statusGreen, no token for subtle exists
  static const _warningColor = AppColors.statusWarning;
  static const _warningSubtle = Color(
    0x1AEAB308,
  ); // Intentional: alpha variant of statusWarning, no token for subtle exists

  bool get _isDone => maintenance.mode == MaintenanceMode.completed;

  _BadgeStyle _badgeStyle(BuildContext context) {
    if (_isDone) {
      return _BadgeStyle(
        color: _successColor,
        background: _successSubtle,
        label: context.l10n.maintenance_status_done_badge,
      );
    }
    final status = MaintenanceModel.calculateStatus(
      maintenance,
      vehicle?.currentMileage ?? 0,
    );
    return switch (status) {
      MaintenanceStatus.overdue => _BadgeStyle(
        color: AppColors.error,
        background: AppColors.statusError.withValues(alpha: 0.1),
        label: context.l10n.maintenance_status_overdue,
      ),
      MaintenanceStatus.next => _BadgeStyle(
        color: _warningColor,
        background: _warningSubtle,
        label: context.l10n.maintenance_status_scheduled_badge,
      ),
      _ => _BadgeStyle(
        color: AppColors.primary,
        background: AppColors.primarySubtle,
        label: context.l10n.maintenance_status_scheduled_badge,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = MaintenanceTypeStyle.color(maintenance.type);
    final vehicleLabel = vehicle != null
        ? '${vehicle!.brand} ${vehicle!.model} · ${vehicle!.year}'
        : null;
    final badge = _badgeStyle(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              MaintenanceTypeStyle.icon(maintenance.type),
              color: typeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maintenance.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                if (vehicleLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    vehicleLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badge.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: badge.color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
