import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_specs_row.dart';

class VehicleFormSpecsSection extends StatelessWidget {
  const VehicleFormSpecsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VehicleFormSectionHeader(
          title: context.l10n.vehicle_form_specs_section,
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.darkTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Opcional',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
          ),
          trailing: GestureDetector(
            onTap: () {
              // TODO: implement AI search for specs
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Buscar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorderPrimary, width: 1),
          ),
          child: Column(
            children: [
              VehicleSpecsRow(
                fieldName: VehicleFormFields.engine,
                label: context.l10n.vehicle_form_specs_engine_label,
                hintText: context.l10n.vehicle_form_specs_engine_hint,
              ),
              VehicleSpecsRow(
                fieldName: VehicleFormFields.horsepower,
                label: context.l10n.vehicle_form_specs_horsepower_label,
                hintText: context.l10n.vehicle_form_specs_horsepower_hint,
                showDividerAbove: true,
              ),
              VehicleSpecsRow(
                fieldName: VehicleFormFields.torque,
                label: context.l10n.vehicle_form_specs_torque_label,
                hintText: context.l10n.vehicle_form_specs_torque_hint,
                showDividerAbove: true,
              ),
              VehicleSpecsRow(
                fieldName: VehicleFormFields.weight,
                label: context.l10n.vehicle_form_specs_weight_label,
                hintText: context.l10n.vehicle_form_specs_weight_hint,
                showDividerAbove: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
