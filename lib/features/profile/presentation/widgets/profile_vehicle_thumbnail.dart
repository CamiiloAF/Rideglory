import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../domain/rider_vehicle_preview.dart';
import 'vehicle_thumbnail_placeholder.dart';

/// Miniatura de una moto del garaje en la fila "MIS MOTOS" de la ficha del
/// rider.
///
/// Pencil: iFssW
class ProfileVehicleThumbnail extends StatelessWidget {
  const ProfileVehicleThumbnail({required this.vehicle, super.key});

  final RiderVehiclePreview vehicle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 106,
            height: 76,
            child: vehicle.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: vehicle.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        VehicleThumbnailPlaceholder(colors: colors),
                  )
                : VehicleThumbnailPlaceholder(colors: colors),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 106,
          child: Text(
            vehicle.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
        ),
      ],
    );
  }
}
