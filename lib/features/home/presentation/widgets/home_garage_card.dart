import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/presentation/widgets/home_vehicle_info_row.dart';
import 'package:rideglory/features/home/presentation/widgets/home_vehicle_placeholder_image.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class HomeGarageCard extends StatelessWidget {
  const HomeGarageCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vehicle.imageUrl != null
              ? SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: vehicle.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const HomeVehiclePlaceholderImage(),
                    errorWidget: (_, _, _) =>
                        const HomeVehiclePlaceholderImage(),
                  ),
                )
              : const HomeVehiclePlaceholderImage(),
          HomeVehicleInfoRow(vehicle: vehicle),
        ],
      ),
    );
  }
}
