import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart';
import 'package:rideglory/shared/widgets/form/app_autocomplete_field.dart';
import 'package:rideglory/shared/widgets/form/app_mileage_field.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class VehicleFormBasicSection extends StatelessWidget {
  const VehicleFormBasicSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VehicleFormSectionHeader(title: context.l10n.vehicle_form_info_section),
        const SizedBox(height: 14),
        AppTextField(
          name: VehicleFormFields.name,
          labelText: context.l10n.vehicle_vehicleName,
          isRequired: true,
          hintText: context.l10n.vehicle_vehicleNameHint,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.vehicle_nameRequired,
            ),
            FormBuilderValidators.minLength(
              3,
              errorText: context.l10n.vehicle_minCharacters,
            ),
          ]),
        ),
        const SizedBox(height: 14),
        AppAutocompleteField(
          name: VehicleFormFields.brand,
          labelText: context.l10n.vehicle_form_brand_label,
          isRequired: true,
          hintText: context.l10n.vehicle_vehicleBrandHint,
          suggestionsPrefixIcon: Icons.category_outlined,
          suggestions: ColombiaMotosBrandsData.search,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.vehicle_brandRequired,
            ),
            (value) {
              if (value == null || value.trim().isEmpty) return null;
              const allowed = ColombiaMotosBrandsData.brands;
              return allowed.any((brand) => brand == value.trim())
                  ? null
                  : context.l10n.vehicle_brandMustBeFromList;
            },
          ]),
        ),
        const SizedBox(height: 14),
        AppTextField(
          name: VehicleFormFields.model,
          labelText: context.l10n.vehicle_form_model_label,
          hintText: context.l10n.vehicle_vehicleModelHint,
          isRequired: true,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.vehicle_modelRequired,
            ),
          ]),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                name: VehicleFormFields.year,
                labelText: context.l10n.vehicle_form_year_label,
                isRequired: true,
                hintText: context.l10n.vehicle_vehicleYearHint,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.vehicle_yearRequired,
                  ),
                  FormBuilderValidators.numeric(
                    errorText: context.l10n.mustBeNumber,
                    checkNullOrEmpty: false,
                  ),
                  FormBuilderValidators.min(
                    1900,
                    errorText: context.l10n.vehicle_invalidYear,
                    checkNullOrEmpty: false,
                  ),
                  FormBuilderValidators.max(
                    DateTime.now().year + 2,
                    errorText: context.l10n.vehicle_invalidYear,
                    checkNullOrEmpty: false,
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                name: VehicleFormFields.color,
                labelText: context.l10n.vehicle_form_color_label,
                hintText: context.l10n.vehicle_form_color_hint,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppMileageField(
          name: VehicleFormFields.currentMileage,
          labelText: context.l10n.vehicle_form_km_label,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}
