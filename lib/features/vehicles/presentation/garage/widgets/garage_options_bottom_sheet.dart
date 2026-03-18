import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class GarageOptionsBottomSheet extends StatelessWidget {
  const GarageOptionsBottomSheet({super.key, required this.vehicle});

  final VehicleModel vehicle;

  static void show(BuildContext context, VehicleModel vehicle) {
    final vehicleCubit = context.read<VehicleCubit>();
    final deleteCubit = getIt<VehicleDeleteCubit>()..reset();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => BlocProvider<VehicleCubit>.value(
        value: vehicleCubit,
        child: BlocProvider<VehicleDeleteCubit>.value(
          value: deleteCubit,
          child: BlocListener<VehicleDeleteCubit, VehicleDeleteState>(
            listener: (ctx, state) {
              state.whenOrNull(
                success: (_) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.vehicle_vehicleDeleted),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                error: (message) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: ctx.colorScheme.error,
                    ),
                  );
                },
              );
            },
            child: GarageOptionsBottomSheet(vehicle: vehicle),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.white),
            title: Text(
              context.l10n.vehicle_editVehicle,
              style: context.bodyLarge?.copyWith(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AppRoutes.editVehicle, extra: vehicle);
            },
          ),
          ListTile(
            leading: Icon(Icons.build, color: context.colorScheme.primary),
            title: Text(
              context.l10n.vehicle_addMaintenance,
              style: context.bodyLarge?.copyWith(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AppRoutes.createMaintenance, extra: vehicle);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              context.l10n.vehicle_deleteVehicle,
              style: context.bodyLarge?.copyWith(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              final vehicleCubit = context.read<VehicleCubit>();
              context.read<VehicleDeleteCubit>().deleteVehicle(
                vehicle.id!,
                availableVehicles: vehicleCubit.availableVehicles,
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
