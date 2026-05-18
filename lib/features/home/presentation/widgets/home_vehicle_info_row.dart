import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

enum _AlertLevel { none, upcoming, overdue }

class _MaintenanceAlert {
  const _MaintenanceAlert({
    required this.level,
    required this.label,
  });
  final _AlertLevel level;
  final String label;
}

class HomeVehicleInfoRow extends StatelessWidget {
  const HomeVehicleInfoRow({super.key, required this.vehicle});

  final VehicleModel vehicle;

  Future<_MaintenanceAlert> _loadMaintenanceAlert() async {
    final vehicleId = vehicle.id;
    if (vehicleId == null) return const _MaintenanceAlert(level: _AlertLevel.none, label: '');

    final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
    final result = await useCase.execute(vehicleId);

    return result.fold(
      (_) => const _MaintenanceAlert(level: _AlertLevel.none, label: ''),
      (page) {
        final scheduled = page.items
            .where((m) => m.mode == MaintenanceMode.scheduled)
            .toList();
        if (scheduled.isEmpty) {
          return const _MaintenanceAlert(level: _AlertLevel.none, label: '');
        }

        final currentMileage = vehicle.currentMileage;
        final now = DateTime.now();
        _MaintenanceAlert? upcomingAlert;

        for (final m in scheduled) {
          if (m.nextOdometer != null && currentMileage >= m.nextOdometer!) {
            return _MaintenanceAlert(
              level: _AlertLevel.overdue,
              label: '${m.name} · vencido',
            );
          }
          if (m.nextDate != null && now.isAfter(m.nextDate!)) {
            return _MaintenanceAlert(
              level: _AlertLevel.overdue,
              label: '${m.name} · vencido',
            );
          }
          if (upcomingAlert == null && m.nextOdometer != null) {
            final delta = m.nextOdometer! - currentMileage;
            if (delta > 0 && delta < 100) {
              upcomingAlert = _MaintenanceAlert(
                level: _AlertLevel.upcoming,
                label: '${m.name} · $delta km',
              );
            }
          }
          if (upcomingAlert == null && m.nextDate != null) {
            final daysLeft = m.nextDate!.difference(now).inDays;
            if (daysLeft >= 0 && daysLeft < 7) {
              upcomingAlert = _MaintenanceAlert(
                level: _AlertLevel.upcoming,
                label: '${m.name} · $daysLeft días',
              );
            }
          }
        }

        return upcomingAlert ?? const _MaintenanceAlert(level: _AlertLevel.none, label: '');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle.name,
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapXs,
          FutureBuilder<_MaintenanceAlert>(
            future: _loadMaintenanceAlert(),
            builder: (context, snapshot) {
              final alert = snapshot.data;
              if (alert == null || alert.level == _AlertLevel.none) {
                return const SizedBox.shrink();
              }

              final isOverdue = alert.level == _AlertLevel.overdue;
              final color = isOverdue
                  ? AppColors.error
                  : const Color(0xFFEAB308);
              final bgColor = isOverdue
                  ? const Color(0x1AEF4444)
                  : const Color(0x1AEAB308);
              final icon = isOverdue
                  ? Icons.warning_amber_outlined
                  : Icons.schedule_outlined;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 13),
                    AppSpacing.hGapXxs,
                    Text(
                      alert.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
