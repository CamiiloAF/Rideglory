import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_placa_field.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_vin_field.dart';

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
        const VehicleFormPlacaField(),
        const SizedBox(height: 14),
        const VehicleFormVinField(),
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
