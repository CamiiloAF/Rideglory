import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart';

class VehicleFormIdSection extends StatelessWidget {
  const VehicleFormIdSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VehicleFormSectionHeader(
          title: context.l10n.vehicle_form_id_section,
        ),
        const SizedBox(height: 14),
        const _VehiclePlacaField(),
        const SizedBox(height: 14),
        const _VehicleVinField(),
        const SizedBox(height: 14),
        AppDatePicker(
          fieldName: VehicleFormFields.purchaseDate,
          labelText: context.l10n.vehicle_purchaseDate,
          lastDate: DateTime.now(),
          hintText: context.l10n.vehicle_purchaseDateHint,
        ),
      ],
    );
  }
}

class _VehiclePlacaField extends StatelessWidget {
  const _VehiclePlacaField();

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

class _VehicleVinField extends StatelessWidget {
  const _VehicleVinField();

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
