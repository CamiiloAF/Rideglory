import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class HomeVehicleInfoRow extends StatelessWidget {
  const HomeVehicleInfoRow({super.key, required this.vehicle});

  final VehicleModel vehicle;

  Future<int?> _loadNextOilChangeMileage() async {
    final vehicleId = vehicle.id;
    if (vehicleId == null) return null;

    final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
    final result = await useCase.execute(vehicleId);

    return result.fold(
      (_) => null,
      (maintenances) {
        final oilMaintenances = maintenances
            .where((m) => m.type == MaintenanceType.oilChange)
            .toList();

        if (oilMaintenances.isEmpty) return null;

        oilMaintenances.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        for (final m in oilMaintenances) {
          final nextMileage = m.nextMaintenanceMileage;
          if (nextMileage != null) return nextMileage;
        }

        return null;
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
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 13,
                ),
                const SizedBox(width: 4),
                FutureBuilder<int?>(
                  future: _loadNextOilChangeMileage(),
                  builder: (context, snapshot) {
                    final nextMileage = snapshot.data;
                    final text = nextMileage != null
                        ? '${HomeStrings.nextOilChange} $nextMileage km'
                        : HomeStrings.nextOilChange;

                    return Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
