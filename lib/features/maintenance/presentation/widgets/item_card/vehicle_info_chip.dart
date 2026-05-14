import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleInfoChip extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleInfoChip({super.key, required this.vehicle});

  IconData get _vehicleIcon => Icons.two_wheeler_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_vehicleIcon, size: 16, color: AppColors.darkTextSecondary),
          AppSpacing.hGapSm,
          Text(
            vehicle.name,
            style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          if (vehicle.brand != null) ...[
            AppSpacing.hGapXxs,
            Text('• ${vehicle.brand}', style: context.bodySmall),
          ],
        ],
      ),
    );
  }
}
