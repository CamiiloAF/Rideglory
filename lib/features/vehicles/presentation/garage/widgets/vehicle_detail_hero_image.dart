import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_image_placeholder.dart';

class VehicleDetailHeroImage extends StatelessWidget {
  const VehicleDetailHeroImage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          vehicle.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: vehicle.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const VehicleDetailImagePlaceholder(),
                  errorWidget: (_, _, _) => const VehicleDetailImagePlaceholder(),
                )
              : const VehicleDetailImagePlaceholder(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent, // Intentional: gradient stop — transparent start
                  AppColors.darkBgPrimary.withValues(alpha: 0.8),
                  AppColors.darkBgPrimary,
                ],
                stops: const [0.3, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
