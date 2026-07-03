import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_vehicle_selector.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_data_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_empty_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_error_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_loading_widget.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MaintenancesPageView extends StatefulWidget {
  final bool showVehicleSelector;
  final bool readOnly;

  const MaintenancesPageView({
    super.key,
    required this.showVehicleSelector,
    this.readOnly = false,
  });

  @override
  State<MaintenancesPageView> createState() => _MaintenancesPageViewState();
}

class _MaintenancesPageViewState extends State<MaintenancesPageView> {
  Future<void> _showFiltersBottomSheet() async {
    final cubit = context.read<MaintenancesCubit>();
    final vehicleCubit = context.read<VehicleCubit>();
    final currentFilters = cubit.filters;

    // Strip vehicleIds before passing to the sheet — they are managed externally
    // (set via setInitialVehicleFilter) and are not configurable inside the sheet.
    // This prevents the sheet from opening with a phantom active filter indicator.
    final result = await showModalBottomSheet<MaintenanceFilters>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaintenanceFiltersBottomSheet(
        initialFilters: currentFilters.copyWith(vehicleIds: []),
        availableVehicles: vehicleCubit.availableVehicles
            .where((vehicle) => !vehicle.isArchived)
            .toList(),
      ),
    );

    if (result != null && mounted) {
      // Restore vehicleIds that are not managed by the sheet.
      await cubit.updateFilters(
        result.copyWith(vehicleIds: currentFilters.vehicleIds),
      );
    }
  }

  Future<void> _onVehicleChanged(VehicleModel vehicle) async {
    if (vehicle.id == null) return;
    final cubit = context.read<MaintenancesCubit>();
    cubit.setCurrentVehicleMileage(vehicle.currentMileage);
    await cubit.updateFilters(
      cubit.filters.copyWith(vehicleIds: [vehicle.id!]),
    );
  }

  Future<void> _onTap(MaintenanceModel maintenance) async {
    if (maintenance.id == null) return;
    final result = await context.pushNamed<dynamic>(
      AppRoutes.maintenanceDetail,
      extra: maintenance,
    );
    if (!mounted || result == null) return;
    if (result is MaintenanceModel) {
      context.read<MaintenancesCubit>().updateMaintenanceLocally(result);
    } else if (result is Map && result['action'] == 'deleted') {
      context.read<MaintenancesCubit>().deleteMaintenanceLocally(
        result['deletedId'] as String,
      );
    }
  }

  Future<void> _onTapReadOnly(MaintenanceModel maintenance) async {
    if (maintenance.id == null) return;
    await context.pushNamed<dynamic>(
      AppRoutes.maintenanceDetail,
      extra: <String, dynamic>{'maintenance': maintenance, 'readOnly': true},
    );
  }

  Future<void> _onAddMaintenance() async {
    // Form pops with List<MaintenanceModel> (1 or 2 records if auto-created scheduled).
    // Pasamos el vehículo activo del filtro para que el form lo preseleccione
    // y el nuevo registro caiga en el mismo vehículo que está viendo el usuario.
    final activeVehicle = _resolveSelectedVehicle(context);
    final result = await context.pushNamed<dynamic>(
      AppRoutes.createMaintenance,
      extra: activeVehicle,
    );
    if (!mounted) return;
    if (result is List<MaintenanceModel>) {
      context.read<MaintenancesCubit>().addMaintenancesLocally(result);
    } else if (result is MaintenanceModel) {
      context.read<MaintenancesCubit>().addMaintenanceLocally(result);
    }
  }

  Future<void> _onRefresh() =>
      context.read<MaintenancesCubit>().fetchMaintenances();

  VehicleModel? _resolveSelectedVehicle(BuildContext context) {
    final vehicleIds = context.read<MaintenancesCubit>().filters.vehicleIds;
    if (vehicleIds.isEmpty) return null;
    try {
      return context.read<VehicleCubit>().availableVehicles.firstWhere(
        (vehicle) => vehicle.id == vehicleIds.first,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              AppCircleIconButton.back(
                hasBorder: true,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.goAndClearStack(AppRoutes.home);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.maintenance_maintenances,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Row(
                children: [
                  AppCircleIconButton(
                    icon: Icons.tune,
                    hasBorder: true,
                    onTap: _showFiltersBottomSheet,
                  ),
                  if (!widget.readOnly) ...[
                    const SizedBox(width: 8),
                    AppCircleIconButton(
                      icon: Icons.add,
                      variant: AppCircleIconButtonVariant.accent,
                      onTap: _onAddMaintenance,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MaintenanceDeleteCubit, MaintenanceDeleteState>(
            listener: (context, state) {
              state.whenOrNull(
                success: (deletedId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.maintenance_maintenanceDeletedSuccessfully,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.read<MaintenancesCubit>().deleteMaintenanceLocally(
                    deletedId,
                  );
                },
                error: (message) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.errorMessage(message)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
              );
            },
          ),
        ],
        child: Column(
          children: [
            if (widget.showVehicleSelector)
              BlocBuilder<
                MaintenancesCubit,
                ResultState<List<MaintenanceModel>>
              >(
                builder: (context, _) {
                  final selectedVehicle = _resolveSelectedVehicle(context);
                  final availableVehicles = context
                      .read<VehicleCubit>()
                      .availableVehicles
                      .where((vehicle) => !vehicle.isArchived)
                      .toList();
                  if (selectedVehicle == null) return const SizedBox.shrink();
                  return MaintenanceVehicleSelector(
                    selectedVehicle: selectedVehicle,
                    availableVehicles: availableVehicles,
                    onVehicleChanged: _onVehicleChanged,
                  );
                },
              ),
            Expanded(
              child:
                  BlocBuilder<
                    MaintenancesCubit,
                    ResultState<List<MaintenanceModel>>
                  >(
                    builder: (context, state) => state.maybeWhen(
                      loading: () =>
                          MaintenancesLoadingWidget(onRefresh: _onRefresh),
                      error: (error) => MaintenancesErrorWidget(
                        error: error.message,
                        onRefresh: _onRefresh,
                      ),
                      empty: () => MaintenancesEmptyWidget(
                        onRefresh: _onRefresh,
                        onActionPressed: _onAddMaintenance,
                      ),
                      data: (maintenances) => MaintenancesDataWidget(
                        maintenances: maintenances,
                        onRefresh: _onRefresh,
                        onTap: widget.readOnly ? _onTapReadOnly : _onTap,
                        onFilterPressed: _showFiltersBottomSheet,
                        onAddPressed: _onAddMaintenance,
                      ),
                      orElse: () =>
                          MaintenancesLoadingWidget(onRefresh: _onRefresh),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
