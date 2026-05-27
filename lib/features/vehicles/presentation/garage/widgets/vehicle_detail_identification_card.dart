import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_card_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_copy_button.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_identification_row.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_row_divider.dart';

class VehicleDetailIdentificationCard extends StatelessWidget {
  const VehicleDetailIdentificationCard({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final plate = vehicle.licensePlate;
    final vin = vehicle.vin;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleDetailCardHeader(
            icon: Icons.badge_outlined,
            label: context.l10n.vehicle_identification,
          ),
          if (plate != null) ...[
            VehicleDetailIdentificationRow(
              iconBg: AppColors.primarySubtle,
              icon: Icons.directions_car_outlined,
              iconColor: AppColors.primary,
              label: context.l10n.vehicle_plate,
              child: Text(
                plate,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
          if (plate != null && vin != null)
            const VehicleDetailRowDivider(),
          if (vin != null)
            VehicleDetailIdentificationRow(
              iconBg: AppColors.darkTertiary,
              icon: Icons.numbers,
              iconColor: AppColors.textOnDarkSecondary,
              label: context.l10n.vehicle_vinLabel,
              trailing: VehicleDetailCopyButton(text: vin),
              child: Text(
                vin,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
