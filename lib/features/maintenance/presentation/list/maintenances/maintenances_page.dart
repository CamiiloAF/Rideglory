import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/expandable_fab.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppAppBar(
        title: 'Mantenimientos',
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car_outlined),
            onPressed: () {
              context.pushNamed(AppRoutes.vehicles);
            },
            tooltip: 'Mis Vehículos',
          ),
        ],
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
              state.when(
                initial: () {},
                loading: () {},
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
        child: BlocBuilder<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
          builder: (context, state) {
            Future<void> onRefresh() async {
              await context.read<MaintenancesCubit>().fetchMaintenances();
            }

            return state.maybeWhen(
              orElse: () => ContainerPullToRefresh(
                onRefresh: onRefresh,
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error) => ContainerPullToRefresh(
                onRefresh: onRefresh,
                child: Center(child: Text('Error: ${error.message}')),
              ),
              empty: () {
                return ContainerPullToRefresh(
                  onRefresh: onRefresh,
                  child: EmptyStateWidget(
                    icon: Icons.build_circle_outlined,
                    title: 'No hay mantenimientos registrados',
                    description:
                        'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo',
                    iconColor: const Color(0xFF6366F1),
                    actionButtonText: 'Agregar mantenimiento',
                    onActionPressed: () async {
                      final result = await context.pushNamed<bool?>(
                        AppRoutes.createMaintenance,
                      );

                      if (result == true && context.mounted) {
                        context.read<MaintenancesCubit>().fetchMaintenances();
                      }
                    },
                  ),
                );
              },
              data: (maintenances) {
                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: maintenances.length,
                    itemBuilder: (context, index) {
                      final maintenance = maintenances[index];
                      return ModernMaintenanceCard(
                        maintenance: maintenance,
                        onTap: () async {
                          if (maintenance.id != null) {
                            final result = await context.pushNamed<bool?>(
                              AppRoutes.editMaintenance,
                              extra: maintenance,
                            );
                            if (result == true && context.mounted) {
                              context
                                  .read<MaintenancesCubit>()
                                  .fetchMaintenances();
                            }
                          }
                        },
                        onEdit: () async {
                          if (maintenance.id != null) {
                            final result = await context.pushNamed<bool?>(
                              AppRoutes.editMaintenance,
                              extra: maintenance,
                            );
                            if (result == true && context.mounted) {
                              context
                                  .read<MaintenancesCubit>()
                                  .fetchMaintenances();
                            }
                          }
                        },
                        onDelete: () {
                          if (maintenance.id != null) {
                            context
                                .read<MaintenanceDeleteCubit>()
                                .deleteMaintenance(maintenance.id!);
                          }
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
