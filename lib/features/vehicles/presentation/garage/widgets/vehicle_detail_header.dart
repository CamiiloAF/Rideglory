import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleDetailHeader extends StatelessWidget {
  const VehicleDetailHeader({
    super.key,
    required this.vehicle,
    required this.onAddVehicle,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onAddVehicle;
  final VoidCallback onOptionsTap;

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
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
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
