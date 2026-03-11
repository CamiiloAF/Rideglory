import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_info_card.dart';

class VehicleQuickInfoSection extends StatelessWidget {
  const VehicleQuickInfoSection({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          VehicleStrings.quickInfo.toUpperCase(),
          style: context.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: VehicleInfoCard(
                icon: Icons.subtitles_outlined, // License Plate icon equivalent
                label: VehicleStrings.licensePlateLabel,
                value: vehicle.licensePlate ?? '-',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: VehicleInfoCard(
                icon: Icons.speed, // Mileage icon equivalent
                label: VehicleStrings.currentMileageLabel,
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
