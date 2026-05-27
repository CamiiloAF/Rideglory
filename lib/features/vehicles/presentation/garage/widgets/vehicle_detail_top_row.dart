import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_main_badge.dart';

class VehicleDetailTopRow extends StatelessWidget {
  const VehicleDetailTopRow({super.key, required this.vehicle});

  final VehicleModel vehicle;

  String get _subtitle {
    final parts = <String>[];
    if (vehicle.year != null) parts.add('${vehicle.year}');
    if (vehicle.model != null) parts.add(vehicle.model!);
    if (vehicle.licensePlate != null) parts.add(vehicle.licensePlate!);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (vehicle.isMainVehicle) ...[
          const VehicleDetailMainBadge(),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            _subtitle,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
