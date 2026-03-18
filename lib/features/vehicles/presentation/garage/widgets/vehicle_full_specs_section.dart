import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_spec_row.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class VehicleFullSpecsSection extends StatelessWidget {
  const VehicleFullSpecsSection({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.vehicle_fullSpecs.toUpperCase(),
          style: context.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Column(
            children: [
              VehicleSpecRow(
                icon: Icons.calendar_today_outlined,
                label: context.l10n.vehicle_vehicleYear,
                value: vehicle.year?.toString() ?? '-',
              ),
              VehicleSpecRow(
                icon: Icons.verified_user_outlined, // VIN icon equivalent
                label: context.l10n.vehicle_vehicleVin,
                value: vehicle.vin ?? '-',
              ),
              VehicleSpecRow(
                icon: Icons.shopping_cart_outlined, // Cart icon equivalent
                label: context.l10n.vehicle_purchaseDate,
                value: vehicle.purchaseDate != null
                    ? DateFormat.yMMMMd().format(vehicle.purchaseDate!)
                    : '-',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
