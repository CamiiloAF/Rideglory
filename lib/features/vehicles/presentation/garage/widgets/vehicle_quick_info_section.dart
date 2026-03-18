import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_info_card.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class VehicleQuickInfoSection extends StatelessWidget {
  const VehicleQuickInfoSection({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.vehicle_quickInfo.toUpperCase(),
          style: context.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: VehicleInfoCard(
                icon: Icons.subtitles_outlined, // License Plate icon equivalent
                label: context.l10n.vehicle_vehiclePlate,
                value: vehicle.licensePlate ?? '-',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: VehicleInfoCard(
                icon: Icons.speed, // Mileage icon equivalent
                label: context.l10n.vehicle_currentMileageLabel,
                value:
                    '${NumberFormat('#,###').format(vehicle.currentMileage)} km',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
