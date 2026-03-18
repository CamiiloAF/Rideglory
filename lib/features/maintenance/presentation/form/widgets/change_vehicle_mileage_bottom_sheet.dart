import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
                  AppSpacing.hGapSm,
                  Text(
                    context.l10n.maintenance_updateMileage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Text(
                context.l10n.maintenance_mileageGreaterThanCurrent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              AppSpacing.gapLg,
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
                          context.l10n.maintenance_current,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${currentMileage ?? 0}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.maintenance_maintenanceLabel,
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
              AppSpacing.gapLg,
              Text(
                context.l10n.maintenance_updateVehicleMileageQuestion,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              AppSpacing.gapLg,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.l10n.maintenance_saveOnly,
                      variant: AppButtonVariant.primary,
                      style: AppButtonStyle.outlined,
                      onPressed: () {
                        saveMaintenance(maintenanceToSave);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: AppButton(
                      label: context.l10n.maintenance_update,
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
