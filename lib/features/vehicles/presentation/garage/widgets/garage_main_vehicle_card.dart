import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicle_content_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicle_image_section.dart';

class GarageMainVehicleCard extends StatelessWidget {
  const GarageMainVehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            GarageVehicleImageSection(
              vehicle: vehicle,
              onOptionsTap: onOptionsTap,
            ),
            GarageVehicleContentSection(vehicle: vehicle, onDetailTap: onTap),
          ],
        ),
      ),
    );
  }
}
