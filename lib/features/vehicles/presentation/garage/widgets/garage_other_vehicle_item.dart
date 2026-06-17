import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicle_status_badge.dart';

class GarageOtherVehicleItem extends StatelessWidget {
  const GarageOtherVehicleItem({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  String _formatKm(int km) => km.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final plateYear = [
      if (vehicle.licensePlate != null) vehicle.licensePlate!,
      if (vehicle.year != null) '${vehicle.year}',
    ].join(' · ');
    final km = '${_formatKm(vehicle.currentMileage)} km';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.darkTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.two_wheeler,
                size: 22,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (plateYear.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            plateYear,
                            style: const TextStyle(
                              color: AppColors.textOnDarkSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(
                            color: AppColors.textOnDarkTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        km,
                        style: const TextStyle(
                          color: AppColors.textOnDarkTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.textOnDarkTertiary,
                  ),
                  onPressed: onOptionsTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 2),
                GarageVehicleStatusBadge(vehicle: vehicle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
