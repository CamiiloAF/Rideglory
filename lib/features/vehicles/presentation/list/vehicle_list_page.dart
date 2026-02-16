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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to create vehicle form
              context.pushNamed(AppRoutes.createVehicle);
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<VehicleDeleteCubit, VehicleDeleteState>(
            listener: (context, state) {
              state.when(
                initial: () {},
                loading: () {},
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
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${error.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<VehicleListCubit>().loadVehicles();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.directions_car_outlined,
                    title: 'No tienes vehículos registrados',
                    description: 'Agrega tu primer vehículo para comenzar',
                    actionButtonText: 'Agregar vehículo',
                    onActionPressed: () {
                      context.pushNamed(AppRoutes.createVehicle);
                    },
                    iconColor: const Color(0xFF6366F1),
                  );
                }

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
                            context.pushNamed(
                              AppRoutes.editVehicle,
                              pathParameters: {'id': vehicle.id!},
                            );
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
}
