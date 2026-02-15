import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class ChangeVehicleMileageDialog extends StatelessWidget {
  const ChangeVehicleMileageDialog({
    super.key,
    required this.context,
    required this.maintenanceToSave,
    required this.currentMileage,
    required this.saveMaintenance,
  });

  final BuildContext context;
  final MaintenanceModel maintenanceToSave;
  final int? currentMileage;
  final void Function(MaintenanceModel maintenanceToSave) saveMaintenance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.speed, size: 32),
      title: const Text('Actualizar kilometraje'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El kilometraje del mantenimiento es mayor al kilometraje actual del vehículo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Actual:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${currentMileage ?? 0} ${maintenanceToSave.distanceUnit.label}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mantenimiento:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${maintenanceToSave.maintanceMileage.toInt()} ${maintenanceToSave.distanceUnit.label}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¿Deseas actualizar el kilometraje del vehículo?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            saveMaintenance(maintenanceToSave);
            Navigator.of(context).pop();
          },
          child: const Text('Guardar sin actualizar'),
        ),
        FilledButton.icon(
          onPressed: () {
            context.read<VehicleCubit>().updateMileage(
              maintenanceToSave.maintanceMileage.toInt(),
            );
            saveMaintenance(maintenanceToSave);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Actualizar'),
        ),
      ],
    );
  }
}
