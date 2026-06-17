import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_option_row.dart';
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
      useRootNavigator: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.darkBorderPrimary, width: 1),
      ),
      builder: (sheetContext) => BlocProvider<VehicleCubit>.value(
        value: vehicleCubit,
        child: BlocProvider<VehicleActionCubit>.value(
          value: actionCubit,
          child: BlocListener<VehicleActionCubit, VehicleActionState>(
            listener: (ctx, state) {
              state.whenOrNull(
                archiveSuccess: (_) {
                  vehicleCubit.archiveLocally(vehicle.id!);
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
                  vehicleCubit.unarchiveLocally(vehicle.id!);
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
                permanentDeleteSuccess: (_) {
                  vehicleCubit.deleteLocally(vehicle.id!);
                  ctx.pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        parentContext.l10n.vehicle_permanentDeleteSuccess,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                error: (message) {
                  ctx.pop();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: parentContext.colorScheme.error,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        SizedBox(
          height: 28,
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A44),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // Header: nombre del vehículo + botón cerrar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.darkTertiary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (vehicle.isArchived) ...[
          GarageOptionRow(
            icon: LucideIcons.archiveRestore,
            label: context.l10n.vehicle_unarchiveVehicle,
            onTap: () => actionCubit.unarchiveVehicle(vehicle),
          ),
          GarageOptionRow(
            icon: LucideIcons.trash2,
            label: context.l10n.vehicle_permanentDeleteAction,
            iconColor: AppColors.error,
            onTap: () async {
              final confirm = await ConfirmationDialog.show(
                context: parentContext,
                title: parentContext.l10n.vehicle_permanentDeleteTitle,
                content: parentContext.l10n.vehicle_permanentDeleteMessage(
                  vehicle.name,
                ),
                cancelLabel: parentContext.l10n.vehicle_permanentDeleteCancel,
                confirmLabel: parentContext.l10n.vehicle_permanentDeleteAction,
                confirmType: DialogActionType.danger,
                isDismissible: true,
              );
              if (confirm != true || !parentContext.mounted) return;
              actionCubit.permanentlyDeleteVehicle(vehicle.id!);
            },
          ),
        ] else ...[
          if (!vehicle.isMainVehicle)
            GarageOptionRow(
              icon: LucideIcons.star,
              label: context.l10n.vehicle_setMainVehicle,
              onTap: () async {
                if (vehicle.id == null) return;
                final cubit = context.read<VehicleCubit>();
                final messenger = ScaffoldMessenger.of(parentContext);
                final errorColor = parentContext.colorScheme.error;
                context.pop();
                final errorMsg = await cubit.setMainVehicle(vehicle.id!);
                if (errorMsg != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(errorMsg),
                      backgroundColor: errorColor,
                    ),
                  );
                }
              },
            ),
          GarageOptionRow(
            icon: LucideIcons.pencil,
            label: context.l10n.vehicle_editVehicle,
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
          GarageOptionRow(
            icon: LucideIcons.wrench,
            label: context.l10n.vehicle_addMaintenance,
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
          GarageOptionRow(
            icon: LucideIcons.archive,
            label: context.l10n.vehicle_archiveVehicle,
            onTap: () async {
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
        const SizedBox(height: 28),
      ],
    );
  }
}
