import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_data_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_empty_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_error_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_loading_widget.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/expandable_fab.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenancesPage extends StatelessWidget {
  final String? initialVehicleId;

  const MaintenancesPage({super.key, this.initialVehicleId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final cubit = MaintenancesCubit(getIt<GetMaintenanceListUseCase>());
            if (initialVehicleId != null) {
              cubit.updateFilters(
                MaintenanceFilters(vehicleIds: [initialVehicleId!]),
              );
            }
            cubit.fetchMaintenances();
            return cubit;
          },
        ),
        BlocProvider(create: (context) => getIt<MaintenanceDeleteCubit>()),
      ],
      child: const _MaintenancesPageView(),
    );
  }
}

class _MaintenancesPageView extends StatefulWidget {
  const _MaintenancesPageView();

  @override
  State<_MaintenancesPageView> createState() => _MaintenancesPageViewState();
}

class _MaintenancesPageViewState extends State<_MaintenancesPageView> {
  bool _showExpandedFab = false;

  Future<void> _showFiltersBottomSheet() async {
    final cubit = context.read<MaintenancesCubit>();
    final vehicleCubit = context.read<VehicleCubit>();

    final result = await showModalBottomSheet<MaintenanceFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaintenanceFiltersBottomSheet(
        initialFilters: cubit.filters,
        availableVehicles: vehicleCubit.availableVehicles
            .where((v) => !v.isArchived)
            .toList(),
      ),
    );

    if (result != null && mounted) {
      cubit.updateFilters(result);
    }
  }

  Future<void> _onTap(MaintenanceModel maintenance) async {
    if (maintenance.id != null) {
      final result = await context.pushNamed<dynamic>(
        AppRoutes.maintenanceDetail,
        extra: maintenance,
      );
      if (mounted && result != null) {
        if (result is MaintenanceModel) {
          context.read<MaintenancesCubit>().updateMaintenanceLocally(result);
        } else if (result is Map && result['action'] == 'deleted') {
          context.read<MaintenancesCubit>().deleteMaintenanceLocally(
            result['deletedId'] as String,
          );
        }
      }
    }
  }

  Future<void> _onEdit(MaintenanceModel maintenance) async {
    if (maintenance.id != null) {
      final result = await context.pushNamed<MaintenanceModel?>(
        AppRoutes.editMaintenance,
        extra: maintenance,
      );
      if (result != null && mounted) {
        context.read<MaintenancesCubit>().updateMaintenanceLocally(result);
      }
    }
  }

  void _onDelete(MaintenanceModel maintenance) {
    if (maintenance.id != null) {
      context.read<MaintenanceDeleteCubit>().deleteMaintenance(maintenance.id!);
    }
  }

  Future<void> _onAddMaintenance() async {
    final result = await context.pushNamed<MaintenanceModel?>(
      AppRoutes.createMaintenance,
    );

    if (result != null && mounted) {
      context.read<MaintenancesCubit>().addMaintenanceLocally(result);
    }
  }

  Future<void> _onRefresh() =>
      context.read<MaintenancesCubit>().fetchMaintenances();

  @override
  Widget build(BuildContext context) {
    final activeFilterCount = context
        .watch<MaintenancesCubit>()
        .filters
        .activeFilterCount;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppAppBar(
        title: context.l10n.maintenance_maintenances,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.goAndClearStack(AppRoutes.home);
          },
        ),
      ),
      floatingActionButton: _showExpandedFab ? const ExpandableFab() : null,
      body: MultiBlocListener(
        listeners: [
          BlocListener<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
            listener: (context, state) {
              setState(() {
                _showExpandedFab = state is! Empty;
              });
            },
          ),
          BlocListener<MaintenanceDeleteCubit, MaintenanceDeleteState>(
            listener: (context, state) {
              state.whenOrNull(
                success: (deletedId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.maintenance_maintenanceDeletedSuccessfully,
                      ),
                      backgroundColor: Colors.green,
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
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
          ),
        ],
        child:
            BlocBuilder<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
              builder: (context, state) => state.maybeWhen(
                loading: () => MaintenancesLoadingWidget(onRefresh: _onRefresh),
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
                  onSearchChanged: (value) {
                    context.read<MaintenancesCubit>().updateSearchQuery(value);
                  },
                  onTap: _onTap,
                  onEdit: _onEdit,
                  onDelete: _onDelete,
                  onFilterPressed: _showFiltersBottomSheet,
                  activeFilterCount: activeFilterCount,
                ),
                orElse: () => MaintenancesLoadingWidget(onRefresh: _onRefresh),
              ),
            ),
      ),
    );
  }
}
