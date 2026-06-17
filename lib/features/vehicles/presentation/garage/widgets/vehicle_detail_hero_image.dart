import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_image_placeholder.dart';
import 'package:rideglory/shared/widgets/fullscreen_image_viewer.dart';

class VehicleDetailHeroImage extends StatelessWidget {
  const VehicleDetailHeroImage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final imageUrl = vehicle.imageUrl;
    final heroTag = 'vehicle-image-${vehicle.id}';

    return GestureDetector(
      onTap: imageUrl != null
          ? () => FullscreenImageViewer.show(
                context,
                imageUrl: imageUrl,
                heroTag: heroTag,
              )
          : null,
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null
                ? Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const VehicleDetailImagePlaceholder(),
                      errorWidget: (_, _, _) =>
                          const VehicleDetailImagePlaceholder(),
                    ),
                  )
                : const VehicleDetailImagePlaceholder(),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.darkBgPrimary.withValues(alpha: 0.8),
                      AppColors.darkBgPrimary,
                    ],
                    stops: const [0.3, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
