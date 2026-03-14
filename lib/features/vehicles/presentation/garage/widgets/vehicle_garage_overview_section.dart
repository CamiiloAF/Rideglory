import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_garage_overview_item.dart';

class VehicleGarageOverviewSection extends StatelessWidget {
  const VehicleGarageOverviewSection({
    super.key,
    required this.totalVehicles,
    required this.totalMileage,
  });

  final int totalVehicles;
  final int totalMileage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              VehicleStrings.garageOverview.toUpperCase(),
              style: context.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.grey[500],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${VehicleStrings.allVehicles} ($totalVehicles)',
                style: context.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: VehicleGarageOverviewItem(
                icon: Icons.directions_car_outlined,
                label: VehicleStrings.total,
                value: '${NumberFormat('#,###').format(totalMileage)} km',
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: VehicleGarageOverviewItem(
                icon: Icons.access_time_outlined,
                label: VehicleStrings.lastRide,
                value: '-', // Fallback, we don't track rides yet.
              ),
            ),
          ],
        ),
      ],
    );
  }
}
