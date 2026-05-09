import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class GarageEmptyState extends StatelessWidget {
  const GarageEmptyState({super.key, this.onVehicleSavedLocally});

  /// After create: form already updated `VehicleCubit`; only sync UI (e.g. PageView).
  final void Function([VehicleModel? focusVehicle])? onVehicleSavedLocally;

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
          AppSpacing.gapLg,
          Text(
            context.l10n.vehicle_noVehicles,
            style: context.titleMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapXxl,
          AppButton(
            onPressed: () async {
              final result =
                  await context.pushNamed(AppRoutes.createVehicle);
              if (!context.mounted || result == null) return;
              onVehicleSavedLocally?.call(
                result is VehicleModel ? result : null,
              );
            },
            icon: Icons.add,
            label: context.l10n.vehicle_addVehicle,
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
