import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleListItem extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleListItem({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.primaryGradient,
                    )
                  : null,
              color: isSelected ? null : AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.overlayMedium
                          : AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      vehicle.vehicleType == VehicleType.motorcycle
                          ? Icons.motorcycle_rounded
                          : Icons.directions_car_rounded,
                      color: isSelected ? Colors.white : context.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: context.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (vehicle.brand != null || vehicle.model != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            [vehicle.brand, vehicle.model]
                                .where((e) => e != null)
                                .join(' '),
                            style: context.bodySmall?.copyWith(
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (vehicle.licensePlate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vehicle.licensePlate!,
                            style: context.labelSmall?.copyWith(
                              color: isSelected
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
