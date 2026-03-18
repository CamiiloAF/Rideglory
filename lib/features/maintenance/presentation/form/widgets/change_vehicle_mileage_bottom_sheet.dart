import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/design_system/design_system.dart';

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
                  Icon(Icons.speed, size: 28),
                  SizedBox(width: 8),
                  Text(
                    MaintenanceStrings.updateMileage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                MaintenanceStrings.mileageGreaterThanCurrent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 16),
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
                          MaintenanceStrings.current,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${currentMileage ?? 0}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          MaintenanceStrings.maintenanceLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${maintenanceToSave.maintanceMileage.toInt()}',
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
              SizedBox(height: 16),
              Text(
                MaintenanceStrings.updateVehicleMileageQuestion,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: MaintenanceStrings.saveOnly,
                      variant: AppButtonVariant.primary,
                      style: AppButtonStyle.outlined,
                      onPressed: () {
                        saveMaintenance(maintenanceToSave);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: MaintenanceStrings.update,
                      icon: Icons.check,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        context.read<VehicleCubit>().updateMileage(
                          maintenanceToSave.maintanceMileage.toInt(),
                        );
                        saveMaintenance(maintenanceToSave);
                        Navigator.of(context).pop();
                      },
                    ),
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
