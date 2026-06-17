import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';

class GarageEmptyState extends StatelessWidget {
  const GarageEmptyState({super.key, this.onVehicleSavedLocally});

  /// After create: form already updated `VehicleCubit`; only sync UI (e.g. PageView).
  final void Function([VehicleModel? focusVehicle])? onVehicleSavedLocally;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.two_wheeler_rounded,
      title: context.l10n.vehicle_noVehicles,
      description: context.l10n.vehicle_noVehiclesDescription,
      actionButtonText: context.l10n.vehicle_addVehicle,
      onActionPressed: () async {
        final result = await context.pushNamed(AppRoutes.createVehicle);
        if (!context.mounted || result == null) return;
        onVehicleSavedLocally?.call(result is VehicleModel ? result : null);
      },
    );
  }
}
