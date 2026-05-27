import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart';

class MaintenanceRightBadge extends StatelessWidget {
  final MaintenanceModel maintenance;
  final MaintenanceItemStatus status;
  final Color statusColor;
  final int currentMileage;

  const MaintenanceRightBadge({
    super.key,
    required this.maintenance,
    required this.status,
    required this.statusColor,
    required this.currentMileage,
  });

  int? _kmDelta() {
    final next = maintenance.nextOdometer;
    if (next == null) return null;
    return (next - currentMileage).abs();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    if (maintenance.mode == MaintenanceMode.completed) {
      return const SizedBox.shrink();
    }
    if (maintenance.nextOdometer != null) {
      final delta = _kmDelta();
      final km = numberFormat.format(delta ?? maintenance.nextOdometer);
      final label = status == MaintenanceItemStatus.overdue
          ? context.l10n.maintenance_expired_label
          : context.l10n.maintenance_km_remaining;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$km km',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
