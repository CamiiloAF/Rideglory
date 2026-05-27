import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';

class VehicleFormVinField extends StatelessWidget {
  const VehicleFormVinField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              context.l10n.vehicle_vehicleVin,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.vehicle_form_vin_optional_label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppTextField(
          name: VehicleFormFields.vin,
          textCapitalization: TextCapitalization.characters,
          maxLength: 17,
          hintText: context.l10n.vehicle_vehicleVinHint,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}
