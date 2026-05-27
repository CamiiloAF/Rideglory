import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';

class VehicleFormPlacaField extends StatelessWidget {
  const VehicleFormPlacaField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              context.l10n.vehicle_form_plate_label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                context.l10n.vehicle_form_placa_required_badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppTextField(
          name: VehicleFormFields.licensePlate,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          hintText: context.l10n.vehicle_vehiclePlateHint,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}
