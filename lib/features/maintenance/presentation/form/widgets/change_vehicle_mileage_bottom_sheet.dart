import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class ChangeVehicleMileageBottomSheet extends StatelessWidget {
  const ChangeVehicleMileageBottomSheet({
    super.key,
    required this.maintenanceToSave,
    required this.currentMileage,
    required this.saveMaintenance,
  });

  final MaintenanceModel maintenanceToSave;
  final int? currentMileage;
  final void Function(MaintenanceModel maintenanceToSave) saveMaintenance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Actualizar kilometraje',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'El kilometraje del mantenimiento es mayor al kilometraje actual del vehículo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      saveMaintenance(maintenanceToSave);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Guardar sin actualizar'),
                  ),
                  const SizedBox(width: 8),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
