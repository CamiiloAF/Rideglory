import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/expandable_fab.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';

class MaintenancesPage extends StatefulWidget {
  const MaintenancesPage({super.key});

  @override
  State<MaintenancesPage> createState() => _MaintenancesPageState();
}

class _MaintenancesPageState extends State<MaintenancesPage> {
  bool _showExpandedFab = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MaintenancesCubit(getIt<GetMaintenanceListUseCase>())
            ..fetchMaintenances(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text('Mantenimientos')),
        floatingActionButton: _showExpandedFab ? const ExpandableFab() : null,
        body: BlocConsumer<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
          listener: (context, state) {
            setState(() {
              _showExpandedFab =
                  state is Data && (state as Data).data.isNotEmpty;
            });
          },
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
              data: (maintenances) {
                if (maintenances.isEmpty) {
                  return ContainerPullToRefresh(
                    onRefresh: onRefresh,
                    child: EmptyStateWidget(
                      icon: Icons.build_circle_outlined,
                      title: 'No hay mantenimientos registrados',
                      description:
                          'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo',
                      iconColor: Color(0xFF6366F1),
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
                }

                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: maintenances.length,
                    itemBuilder: (context, index) {
                      final maintenance = maintenances[index];
                      return ModernMaintenanceCard(maintenance: maintenance);
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
