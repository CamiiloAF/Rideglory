import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailHeader extends StatelessWidget {
  const VehicleDetailHeader({
    super.key,
    required this.vehicle,
    required this.onAddVehicle,
    required this.onOptionsTap,
    required this.isMainVehicle,
    this.onMainVehicleChanged,
  });

  final VehicleModel vehicle;
  final VoidCallback onAddVehicle;
  final VoidCallback onOptionsTap;
  final bool isMainVehicle;
  final ValueChanged<bool>? onMainVehicleChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      vehicle.name,
                      style: context.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: onOptionsTap,
                  ),
                ],
              ),
              Text(
                _getBrandAndModel(),
                style: context.bodyLarge?.copyWith(color: Colors.grey[400]),
              ),

              if (onMainVehicleChanged != null) ...[
                AppSpacing.gapSm,
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: isMainVehicle
                          ? context.colorScheme.primary
                          : Colors.white.withValues(alpha: 0.4),
                    ),

                    AppSpacing.hGapXs,
                    Text(
                      context.l10n.vehicle_mainVehicle,
                      style: context.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: isMainVehicle,
                      activeTrackColor: context.colorScheme.primary,
                      onChanged: onMainVehicleChanged,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        InkWell(
          onTap: onAddVehicle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ],
    );
  }

  String _getBrandAndModel() {
    return [vehicle.brand, vehicle.model]
        .where((element) => element != null && element.isNotEmpty)
        .join(' ')
        .trim();
  }
}
