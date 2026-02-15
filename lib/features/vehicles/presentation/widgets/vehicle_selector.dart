import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';

class VehicleSelector extends StatelessWidget {
  const VehicleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleListCubit, ResultState<List<VehicleModel>>>(
      builder: (context, listState) {
        return BlocBuilder<VehicleCubit, VehicleState>(
          builder: (context, vehicleState) {
            final currentVehicle = context.read<VehicleCubit>().currentVehicle;

            return listState.maybeWhen(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<VehicleModel>(
                            value: currentVehicle,
                            isExpanded: true,
                            hint: const Text('Select a vehicle'),
                            items: vehicles.map((vehicle) {
                              return DropdownMenuItem<VehicleModel>(
                                value: vehicle,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      vehicle.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (vehicle.brand != null ||
                                        vehicle.model != null)
                                      Text(
                                        [
                                          vehicle.brand,
                                          vehicle.model,
                                        ].where((e) => e != null).join(' '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (vehicle) {
                              if (vehicle != null) {
                                context.read<VehicleCubit>().setCurrentVehicle(
                                  vehicle,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
