import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_data_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_empty_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_error_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_loading_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_page_app_bar.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/expandable_fab.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';

class MaintenancesPage extends StatelessWidget {
  const MaintenancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MaintenancesCubit(getIt<GetMaintenanceListUseCase>())
                ..fetchMaintenances(),
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
    final vehicleListCubit = context.read<VehicleListCubit>();

    final result = await showModalBottomSheet<MaintenanceFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaintenanceFiltersBottomSheet(
        initialFilters: cubit.filters,
        availableVehicles: vehicleListCubit.activeVehicles,
      ),
    );

    if (result != null && mounted) {
      cubit.updateFilters(result);
    }
  }

  Future<void> _onTap(MaintenanceModel maintenance) async {
    if (maintenance.id != null) {
      final result = await context.pushNamed<bool?>(
        AppRoutes.editMaintenance,
        extra: maintenance,
      );
      if (result == true && mounted) {
        context.read<MaintenancesCubit>().fetchMaintenances();
      }
    }
  }

  Future<void> _onEdit(MaintenanceModel maintenance) async {
    if (maintenance.id != null) {
      final result = await context.pushNamed<bool?>(
        AppRoutes.editMaintenance,
        extra: maintenance,
      );
      if (result == true && mounted) {
        context.read<MaintenancesCubit>().fetchMaintenances();
      }
    }
  }

  void _onDelete(MaintenanceModel maintenance) {
    if (maintenance.id != null) {
      context.read<MaintenanceDeleteCubit>().deleteMaintenance(maintenance.id!);
    }
  }

  Future<void> _onAddMaintenance() async {
    final result = await context.pushNamed<bool?>(AppRoutes.createMaintenance);

    if (result == true && mounted) {
      context.read<MaintenancesCubit>().fetchMaintenances();
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
      backgroundColor: Colors.grey[50],
      appBar: MaintenancesPageAppBar(
        activeFilterCount: activeFilterCount,
        onFilterPressed: _showFiltersBottomSheet,
        onVehiclesPressed: () => context.pushNamed(AppRoutes.vehicles),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.maintenances),
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
                    const SnackBar(
                      content: Text('Mantenimiento eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.read<MaintenancesCubit>().fetchMaintenances();
                },
                error: (message) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $message'),
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
                  error: error,
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
                ),
                orElse: () => MaintenancesLoadingWidget(onRefresh: _onRefresh),
              ),
            ),
      ),
    );
  }
}
