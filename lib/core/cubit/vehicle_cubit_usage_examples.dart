import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/domain/models/vehicle_model.dart';

/// Este archivo muestra ejemplos de cómo usar el VehicleCubit
/// desde cualquier parte de la aplicación.

// Ejemplo 1: Leer el vehículo actual usando BlocBuilder
class VehicleInfoWidget extends StatelessWidget {
  const VehicleInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, state) {
        if (state is VehicleLoaded) {
          return Column(
            children: [
              Text('Vehículo: ${state.vehicle.name}'),
              Text(
                'Kilometraje: ${state.vehicle.currentMileage} ${state.vehicle.distanceUnit}',
              ),
            ],
          );
        }

        if (state is VehicleEmpty) {
          return const Text('No hay vehículo seleccionado');
        }

        return const Text('Cargando...');
      },
    );
  }
}

// Ejemplo 2: Actualizar el kilometraje
class UpdateMileageExample extends StatelessWidget {
  const UpdateMileageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Acceder al cubit usando context.read
        context.read<VehicleCubit>().updateMileage(50500.0);
      },
      child: const Text('Actualizar kilometraje'),
    );
  }
}

// Ejemplo 3: Establecer un nuevo vehículo
class SetVehicleExample extends StatelessWidget {
  const SetVehicleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final newVehicle = VehicleModel(
          id: '1',
          name: 'Mi Toyota',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          currentMileage: 45000.0,
          distanceUnit: 'KM',
          licensePlate: 'ABC-123',
        );

        context.read<VehicleCubit>().setVehicle(newVehicle);
      },
      child: const Text('Establecer vehículo'),
    );
  }
}

// Ejemplo 4: Obtener solo el kilometraje actual sin escuchar cambios
class GetCurrentMileageExample extends StatelessWidget {
  const GetCurrentMileageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final cubit = context.read<VehicleCubit>();
        final mileage = cubit.currentMileage;

        if (mileage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kilometraje actual: $mileage')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay vehículo seleccionado')),
          );
        }
      },
      child: const Text('Mostrar kilometraje'),
    );
  }
}

// Ejemplo 5: Usar BlocListener para reaccionar a cambios
class VehicleListenerExample extends StatelessWidget {
  const VehicleListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleCubit, VehicleState>(
      listener: (context, state) {
        if (state is VehicleLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehículo actualizado: ${state.vehicle.name}'),
            ),
          );
        }
      },
      child: const Placeholder(),
    );
  }
}

// Ejemplo 6: Combinar BlocBuilder con BlocListener usando BlocConsumer
class VehicleConsumerExample extends StatelessWidget {
  const VehicleConsumerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VehicleCubit, VehicleState>(
      listener: (context, state) {
        // Reacciona a cambios (side effects)
        if (state is VehicleLoaded && state.vehicle.currentMileage > 100000) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Alerta! El vehículo tiene alto kilometraje'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      builder: (context, state) {
        // Construye UI basada en el estado
        if (state is VehicleLoaded) {
          return Card(
            child: ListTile(
              title: Text(state.vehicle.name),
              subtitle: Text(
                '${state.vehicle.currentMileage} ${state.vehicle.distanceUnit}',
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
