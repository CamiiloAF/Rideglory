import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_garage_overview_item.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
              context.l10n.vehicle_garageOverview.toUpperCase(),
              style: context.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.grey[500],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${context.l10n.vehicle_allVehicles} ($totalVehicles)',
                style: context.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapLg,
        Row(
          children: [
            Expanded(
              child: VehicleGarageOverviewItem(
                icon: Icons.directions_car_outlined,
                label: context.l10n.vehicle_total,
                value: '${NumberFormat('#,###').format(totalMileage)} km',
              ),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: VehicleGarageOverviewItem(
                icon: Icons.access_time_outlined,
                label: context.l10n.vehicle_lastRide,
                value: '-', // Fallback, we don't track rides yet.
              ),
            ),
          ],
        ),
      ],
    );
  }
}
