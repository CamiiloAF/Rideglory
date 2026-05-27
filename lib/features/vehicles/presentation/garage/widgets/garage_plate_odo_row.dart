import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class GaragePlateOdoRow extends StatelessWidget {
  const GaragePlateOdoRow({super.key, required this.vehicle});

  final VehicleModel vehicle;

  String _formatKm(int km) => km.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (vehicle.licensePlate != null)
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                vehicle.licensePlate!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        Row(
          children: [
            const Icon(
              Icons.speed,
              size: 16,
              color: AppColors.textOnDarkSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '${_formatKm(vehicle.currentMileage)} km',
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.garage_odometerLabel,
              style: const TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
