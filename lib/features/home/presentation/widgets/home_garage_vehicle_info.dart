import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_soat_badge.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

/// Name and SOAT badge section of the garage card.
class HomeGarageVehicleInfo extends StatelessWidget {
  const HomeGarageVehicleInfo({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle.name,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (vehicle.soatStatus != null || vehicle.soatExpiryDate != null) ...[
            const SizedBox(height: 8),
            HomeGarageSoatBadge(vehicle: vehicle),
          ],
        ],
      ),
    );
  }
}
