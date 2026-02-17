import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';

class VehicleListPage extends StatelessWidget {
  const VehicleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<VehicleListCubit>()..loadVehicles(),
        ),
        BlocProvider(create: (context) => getIt<VehicleDeleteCubit>()),
      ],
      child: const _VehicleListView(),
    );
  }
}

class _VehicleListView extends StatelessWidget {
  const _VehicleListView();

  Future<void> _goToEditVehicle(
    BuildContext context,
    VehicleModel vehicle,
  ) async {
    final result = await context.pushNamed(
      AppRoutes.editVehicle,
      extra: vehicle,
    );
    if (result == true && context.mounted) {
      _loadVechicles(context);
    }
  }

  Future<void> _loadVechicles(BuildContext context) =>
      context.read<VehicleListCubit>().loadVehicles();

  Future<void> _goToCreateVehicle(BuildContext context) async {
    final result = await context.pushNamed(AppRoutes.createVehicle);
    if (result == true && context.mounted) {
      _loadVechicles(context);
    }
  }

  void _showDeleteDialog(BuildContext context, VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete "${vehicle.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (vehicle.id != null) {
                context.read<VehicleDeleteCubit>().deleteVehicle(vehicle.id!);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppAppBar(
        title: 'Mis Vehículos',
        actions: [
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            onPressed: () {
              context.pushNamed(AppRoutes.maintenances);
            },
            tooltip: 'Mantenimientos',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.pushNamed(AppRoutes.createVehicle);
            },
            tooltip: 'Agregar vehículo',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.vehicles),
      body: MultiBlocListener(
        listeners: [
          BlocListener<VehicleDeleteCubit, VehicleDeleteState>(
            listener: (context, state) {
              state.whenOrNull(
                success: (deletedId) {
                  context.read<VehicleListCubit>().removeVehicleFromList(
                    deletedId,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vehicle deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
        child: BlocBuilder<VehicleListCubit, ResultState<List<VehicleModel>>>(
          builder: (context, state) {
            return state.maybeWhen(
              orElse: () => const Center(child: CircularProgressIndicator()),
              error: (error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${error.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _loadVechicles(context);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              empty: () {
                return EmptyStateWidget(
                  icon: Icons.directions_car_outlined,
                  title: 'No tienes vehículos registrados',
                  description: 'Agrega tu primer vehículo para comenzar',
                  actionButtonText: 'Agregar vehículo',
                  onActionPressed: () {
                    _goToCreateVehicle(context);
                  },
                  iconColor: const Color(0xFF6366F1),
                );
              },
              data: (vehicles) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<VehicleListCubit>().loadVehicles();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return VehicleCard(
                        vehicle: vehicle,
                        onTap: () {
                          // Navigate to edit vehicle
                          if (vehicle.id != null) {
                            _goToEditVehicle(context, vehicle);
                          }
                        },
                        onDelete: () {
                          _showDeleteDialog(context, vehicle);
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
