import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class GarageEmptyState extends StatelessWidget {
  const GarageEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.garage_outlined,
            size: 80,
            color: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            VehicleStrings.noVehicles,
            style: context.titleMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24),
          AppButton(
            onPressed: () => context.pushNamed(AppRoutes.createVehicle),
            icon: Icons.add,
            label: VehicleStrings.addVehicle,
            variant: AppButtonVariant.primary,
            style: AppButtonStyle.filled,
            isFullWidth: false,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ],
      ),
    );
  }
}
