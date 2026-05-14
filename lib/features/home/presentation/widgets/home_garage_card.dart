import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';

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
            _HeroImage(vehicle: vehicle),
            _VehicleInfo(vehicle: vehicle),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: vehicle.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: vehicle.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => const _PlaceholderImage(),
              errorWidget: (_, _, _) => const _PlaceholderImage(),
            )
          : const _PlaceholderImage(),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(Icons.two_wheeler, size: 56, color: AppColors.darkBorderLight),
      ),
    );
  }
}

class _VehicleInfo extends StatelessWidget {
  const _VehicleInfo({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Text(
        vehicle.name,
        style: const TextStyle(
          color: AppColors.textOnDarkPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
