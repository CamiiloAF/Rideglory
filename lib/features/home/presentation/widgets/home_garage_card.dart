import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/home/presentation/widgets/home_vehicle_info_row.dart';
import 'package:rideglory/features/home/presentation/widgets/home_vehicle_placeholder_image.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeGarageCard extends StatelessWidget {
  const HomeGarageCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.goNamed(AppRoutes.garage, extra: vehicle.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorScheme.outlineVariant),
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
                      placeholder: (_, _) =>
                          const HomeVehiclePlaceholderImage(),
                      errorWidget: (_, _, _) =>
                          const HomeVehiclePlaceholderImage(),
                    ),
                  )
                : const HomeVehiclePlaceholderImage(),
            HomeVehicleInfoRow(vehicle: vehicle),
          ],
        ),
      ),
    );
  }
}
