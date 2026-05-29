import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleSelectorCard extends StatelessWidget {
  const VehicleSelectorCard({
    super.key,
    required this.vehicle,
    required this.onChange,
  });

  final VehicleModel vehicle;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final title = [
      vehicle.brand,
      vehicle.model,
    ].where((part) => part != null && part.isNotEmpty).join(' ').trim();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.two_wheeler,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.isEmpty ? vehicle.name : title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _VehicleMetaRow(vehicle: vehicle),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _ChangeButton(onTap: onChange),
          ],
        ),
      ),
    );
  }
}

class _VehicleMetaRow extends StatelessWidget {
  const _VehicleMetaRow({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final hasPlate =
        vehicle.licensePlate != null && vehicle.licensePlate!.isNotEmpty;
    final hasYear = vehicle.year != null;

    final children = <Widget>[];

    if (hasPlate) {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.darkBgSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            vehicle.licensePlate!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ),
      );
    }

    if (hasPlate && hasYear) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '·',
            style: TextStyle(fontSize: 13, color: AppColors.textOnDarkTertiary),
          ),
        ),
      );
    }

    if (hasYear) {
      children.add(
        Text(
          vehicle.year!.toString(),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class _ChangeButton extends StatelessWidget {
  const _ChangeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            context.l10n.registration_changeVehicle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
