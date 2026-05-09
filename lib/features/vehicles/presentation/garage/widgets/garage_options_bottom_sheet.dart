import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class GarageOptionsBottomSheet extends StatelessWidget {
  const GarageOptionsBottomSheet({
    super.key,
    required this.vehicle,
    required this.parentContext,
    required this.deleteCubit,
    this.onGarageListUpdatedLocally,
  });

  final VehicleModel vehicle;
  final BuildContext parentContext;
  final VehicleDeleteCubit deleteCubit;
  final void Function([VehicleModel? focusVehicle])? onGarageListUpdatedLocally;

  static void show(
    BuildContext parentContext,
    VehicleModel vehicle, {
    void Function([VehicleModel? focusVehicle])? onGarageListUpdatedLocally,
  }) {
    final vehicleCubit = parentContext.read<VehicleCubit>();
    final deleteCubit = getIt<VehicleDeleteCubit>()..reset();
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: parentContext.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => BlocProvider<VehicleCubit>.value(
        value: vehicleCubit,
        child: BlocProvider<VehicleDeleteCubit>.value(
          value: deleteCubit,
          child: BlocListener<VehicleDeleteCubit, VehicleDeleteState>(
            listener: (ctx, state) {
              state.whenOrNull(
                success: (_) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(parentContext.l10n.vehicle_vehicleDeleted),
                      backgroundColor: Colors.green,
                    ),
                  );
                  onGarageListUpdatedLocally?.call();
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
            child: GarageOptionsBottomSheet(
              vehicle: vehicle,
              parentContext: parentContext,
              onGarageListUpdatedLocally: onGarageListUpdatedLocally,
              deleteCubit: deleteCubit,
            ),
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
            leading: const Icon(Icons.edit, color: Colors.white),
            title: Text(
              context.l10n.vehicle_editVehicle,
              style: context.bodyLarge?.copyWith(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final result = await GoRouter.of(
                parentContext,
              ).pushNamed(AppRoutes.editVehicle, extra: vehicle);
              if (!parentContext.mounted || result == null) return;
              onGarageListUpdatedLocally?.call(
                result is VehicleModel ? result : null,
              );
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
              parentContext.pushNamed(
                AppRoutes.createMaintenance,
                extra: vehicle,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              context.l10n.vehicle_deleteVehicle,
              style: context.bodyLarge?.copyWith(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await ConfirmationDialog.show(
                context: parentContext,
                title: parentContext.l10n.vehicle_deleteVehicle,
                content: parentContext.l10n.vehicle_deleteVehicleConfirmContent(
                  vehicle.name,
                ),
                cancelLabel: parentContext.l10n.cancel,
                confirmLabel: parentContext.l10n.delete,
                confirmType: DialogActionType.danger,
                dialogType: DialogType.warning,
                isDismissible: true,
              );
              if (confirm != true || !parentContext.mounted) return;
              deleteCubit.deleteVehicle(
                vehicle.id!,
                availableVehicles: parentContext
                    .read<VehicleCubit>()
                    .availableVehicles,
              );
            },
          ),
          AppSpacing.gapLg,
        ],
      ),
    );
  }
}
