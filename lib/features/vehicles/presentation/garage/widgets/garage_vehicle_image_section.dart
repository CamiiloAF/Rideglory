import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_main_badge.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicle_placeholder.dart';

class GarageVehicleImageSection extends StatelessWidget {
  const GarageVehicleImageSection({
    super.key,
    required this.vehicle,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onOptionsTap;

  String get _subtitle {
    final brandModel = [
      if (vehicle.brand != null) vehicle.brand!,
      if (vehicle.model != null) vehicle.model!,
    ].join(' ');
    final parts = <String>[];
    if (brandModel.isNotEmpty) parts.add(brandModel);
    if (vehicle.year != null) parts.add('${vehicle.year}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle;
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: AppColors.darkBgSecondary)),
          if (vehicle.imageUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: vehicle.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const GarageVehiclePlaceholder(),
                errorWidget: (_, _, _) => const GarageVehiclePlaceholder(),
              ),
            )
          else
            const Positioned.fill(child: GarageVehiclePlaceholder()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent, // Intentional: gradient stop — transparent start
                    AppColors.darkBgPrimary.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: GestureDetector(
              onTap: onOptionsTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.darkBgPrimary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: AppColors.textOnDarkPrimary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 60,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        vehicle.name,
                        style: const TextStyle(
                          color: AppColors.textOnDarkPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GarageMainBadge(label: context.l10n.garage_mainVehicleBadge),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: 0.9,
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
