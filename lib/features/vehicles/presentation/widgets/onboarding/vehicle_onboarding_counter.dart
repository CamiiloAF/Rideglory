import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';

class VehicleOnboardingCounter extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onAddVehicle;
  final VoidCallback onRemoveVehicle;
  final bool canRemove;

  const VehicleOnboardingCounter({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onAddVehicle,
    required this.onRemoveVehicle,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            VehicleStrings.vehicleCounter(currentPage + 1, totalPages),
            style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              if (canRemove)
                IconButton(
                  onPressed: onRemoveVehicle,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFEF4444),
                  tooltip: VehicleStrings.removeVehicleTooltip,
                ),
              IconButton(
                onPressed: onAddVehicle,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF6366F1),
                tooltip: VehicleStrings.addAnotherVehicleTooltip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
