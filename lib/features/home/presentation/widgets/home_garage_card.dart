import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_hero_image.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_vehicle_info.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class HomeGarageCard extends StatelessWidget {
  const HomeGarageCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.garage),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeGarageHeroImage(vehicle: vehicle),
            HomeGarageVehicleInfo(vehicle: vehicle),
          ],
        ),
      ),
    );
  }
}
