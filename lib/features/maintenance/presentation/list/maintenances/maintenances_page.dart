import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/expandable_fab.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/modern_maintenance_card.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';

class MaintenancesPage extends StatefulWidget {
  const MaintenancesPage({super.key});

  @override
  State<MaintenancesPage> createState() => _MaintenancesPageState();
}

class _MaintenancesPageState extends State<MaintenancesPage> {
  @override
  void initState() {
    super.initState();
    // Establecer un vehículo de ejemplo al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleCubit = context.read<VehicleCubit>();
      if (vehicleCubit.currentVehicle == null) {
        vehicleCubit.setCurrentVehicle(
          const VehicleModel(
            id: '1',
            name: 'Mi Toyota Corolla',
            brand: 'Toyota',
            model: 'Corolla',
            year: 2020,
            currentMileage: 49800,
            distanceUnit: 'KM',
            licensePlate: 'ABC-123',
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MaintenancesCubit(getIt<GetMaintenanceListUseCase>())
            ..fetchMaintenances(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text('Mantenimientos')),
        floatingActionButton: const ExpandableFab(),
        body:
            BlocBuilder<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
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
                  data: (maintenances) => RefreshIndicator(
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
                  ),
                );
              },
            ),
      ),
    );
  }
}
