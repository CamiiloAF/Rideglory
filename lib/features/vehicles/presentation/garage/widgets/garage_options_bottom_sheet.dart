import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class GarageOptionsBottomSheet extends StatelessWidget {
  const GarageOptionsBottomSheet({
    super.key,
    required this.vehicle,
    required this.parentContext,
    required this.actionCubit,
    this.onGarageListUpdatedLocally,
    this.onMaintenanceCreated,
    this.onMaintenanceRefreshRequested,
  });

  final VehicleModel vehicle;
  final BuildContext parentContext;
  final VehicleActionCubit actionCubit;
  final void Function([VehicleModel? focusVehicle])? onGarageListUpdatedLocally;
  final ValueChanged<MaintenanceModel>? onMaintenanceCreated;
  final ValueChanged<String>? onMaintenanceRefreshRequested;

  static void show(
    BuildContext parentContext,
    VehicleModel vehicle, {
    void Function([VehicleModel? focusVehicle])? onGarageListUpdatedLocally,
    ValueChanged<MaintenanceModel>? onMaintenanceCreated,
    ValueChanged<String>? onMaintenanceRefreshRequested,
  }) {
    final vehicleCubit = parentContext.read<VehicleCubit>();
    final actionCubit = getIt<VehicleActionCubit>()..reset();
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider<VehicleCubit>.value(
        value: vehicleCubit,
        child: BlocProvider<VehicleActionCubit>.value(
          value: actionCubit,
          child: BlocListener<VehicleActionCubit, VehicleActionState>(
            listener: (ctx, state) {
              state.whenOrNull(
                success: (_) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(parentContext.l10n.vehicle_vehicleDeleted),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  onGarageListUpdatedLocally?.call();
                },
                archiveSuccess: (_) {
                  ctx.pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        parentContext.l10n.vehicle_vehicleArchived,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                unarchiveSuccess: (_) {
                  ctx.pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        parentContext.l10n.vehicle_vehicleRestored,
                      ),
                      backgroundColor: AppColors.success,
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
            child: GarageOptionsBottomSheet(
              vehicle: vehicle,
              parentContext: parentContext,
              onGarageListUpdatedLocally: onGarageListUpdatedLocally,
              onMaintenanceCreated: onMaintenanceCreated,
              onMaintenanceRefreshRequested: onMaintenanceRefreshRequested,
              actionCubit: actionCubit,
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
              color: AppColors.darkBorderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (vehicle.isArchived) ...[
            // ── Vehículo archivado: solo "Restaurar" ──────────────────────────
            ListTile(
              leading: const Icon(Icons.unarchive, color: Colors.white),
              title: Text(
                context.l10n.vehicle_unarchiveVehicle,
                style: context.bodyLarge?.copyWith(color: Colors.white),
              ),
              onTap: () => actionCubit.unarchiveVehicle(vehicle),
            ),
          ] else ...[
            // ── Vehículo activo: opciones completas ───────────────────────────
            if (!vehicle.isMainVehicle)
              ListTile(
                leading: Icon(
                  Icons.star,
                  color: context.colorScheme.primary,
                ),
                title: Text(
                  context.l10n.vehicle_setMainVehicle,
                  style: context.bodyLarge?.copyWith(color: Colors.white),
                ),
                onTap: () {
                  context.pop();
                  if (vehicle.id != null) {
                    context.read<VehicleCubit>().setMainVehicle(vehicle.id!);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: Text(
                context.l10n.vehicle_editVehicle,
                style: context.bodyLarge?.copyWith(color: Colors.white),
              ),
              onTap: () async {
                context.pop();
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
              onTap: () async {
                context.pop();
                final result = await parentContext.pushNamed<dynamic>(
                  AppRoutes.createMaintenance,
                  extra: vehicle,
                );
                if (!parentContext.mounted || result == null) return;
                if (result is List<MaintenanceModel> && result.isNotEmpty) {
                  onMaintenanceCreated?.call(result.first);
                } else if (result is MaintenanceModel) {
                  onMaintenanceCreated?.call(result);
                } else if (vehicle.id != null) {
                  onMaintenanceRefreshRequested?.call(vehicle.id!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.white),
              title: Text(
                context.l10n.vehicle_archiveVehicle,
                style: context.bodyLarge?.copyWith(color: Colors.white),
              ),
              onTap: () async {
                context.pop();
                final confirm = await ConfirmationDialog.show(
                  context: parentContext,
                  title: parentContext.l10n.vehicle_archiveVehicleConfirmTitle,
                  content: parentContext.l10n.vehicle_archiveVehicleConfirmContent(
                    vehicle.name,
                  ),
                  cancelLabel: parentContext.l10n.cancel,
                  confirmLabel: parentContext.l10n.vehicle_archiveConfirmButton,
                  confirmType: DialogActionType.primary,
                  isDismissible: true,
                );
                if (confirm != true || !parentContext.mounted) return;
                actionCubit.archiveVehicle(vehicle);
              },
            ),
          ],
          AppSpacing.gapLg,
        ],
      ),
    );
  }
}
