import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_data_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_empty_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_error_widget.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_loading_widget.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

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
              cubit.setInitialVehicleFilter(initialVehicleId!);
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
            .where((vehicle) => !vehicle.isArchived)
            .toList(),
      ),
    );

    if (result != null && mounted) {
      await cubit.updateFilters(result);
    }
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
              _AppBarIconButton(
                icon: Icons.arrow_back,
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
                  _AppBarIconButton(
                    icon: Icons.tune,
                    hasBorder: true,
                    onTap: _showFiltersBottomSheet,
                  ),
                  const SizedBox(width: 8),
                  _AppBarIconButton(
                    icon: Icons.add,
                    hasBorder: false,
                    isAccent: true,
                    onTap: _onAddMaintenance,
                  ),
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
        child: BlocBuilder<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
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
              onTap: _onTap,
              onFilterPressed: _showFiltersBottomSheet,
              onAddPressed: _onAddMaintenance,
            ),
            orElse: () => MaintenancesLoadingWidget(onRefresh: _onRefresh),
          ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool hasBorder;
  final bool isAccent;
  final VoidCallback onTap;

  const _AppBarIconButton({
    required this.icon,
    required this.hasBorder,
    this.isAccent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isAccent ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: hasBorder
              ? Border.all(color: AppColors.darkBorderPrimary)
              : null,
        ),
        child: Icon(
          icon,
          color: AppColors.textOnDarkPrimary,
          size: 16,
        ),
      ),
    );
  }
}
