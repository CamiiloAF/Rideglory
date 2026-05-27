import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class GarageVehicleStatusBadge extends StatelessWidget {
  const GarageVehicleStatusBadge({super.key, required this.vehicle});

  final VehicleModel vehicle;

  Future<int> _loadScheduledCount() async {
    final vehicleId = vehicle.id;
    if (vehicleId == null) return 0;

    final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
    final result = await useCase.execute(vehicleId);

    return result.fold(
      (_) => 0,
      (page) =>
          page.items.where((m) => m.mode == MaintenanceMode.scheduled).length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _loadScheduledCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final isUpToDate = count == 0;

        final dotColor = isUpToDate
            ? AppColors.statusGreen
            : AppColors.statusWarning;
        final badgeBg = isUpToDate
            ? AppColors.statusGreen.withValues(alpha: 0.13)
            : AppColors.statusWarning.withValues(alpha: 0.13);
        final label = isUpToDate
            ? context.l10n.garage_upToDate
            : context.l10n.garage_upcomingCount(count);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: dotColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
