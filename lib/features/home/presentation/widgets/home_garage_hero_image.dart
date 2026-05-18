import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_placeholder_image.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

/// Hero image section of the garage card.
class HomeGarageHeroImage extends StatelessWidget {
  const HomeGarageHeroImage({super.key, required this.vehicle});

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
              placeholder: (_, _) => const HomeGaragePlaceholderImage(),
              errorWidget: (_, _, _) => const HomeGaragePlaceholderImage(),
            )
          : const HomeGaragePlaceholderImage(),
    );
  }
}
