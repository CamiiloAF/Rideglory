import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_cover_photo_section.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_documents_section.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_scan_banner.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_section_label.dart';

class VehicleForm extends StatelessWidget {
  const VehicleForm({
    super.key,
    this.formKey,
    this.isEditing = false,
    this.initialValue,
    this.onSave,
  });

  final GlobalKey<FormBuilderState>? formKey;
  final bool isEditing;
  final Map<String, dynamic>? initialValue;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        return FormBuilder(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUnfocus,
          initialValue: initialValue ?? const <String, dynamic>{},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VehicleFormCoverPhotoSection(),
              const SizedBox(height: 16),
              const VehicleFormScanBanner(),
              const SizedBox(height: 20),
              VehicleFormSectionLabel(context.l10n.vehicle_form_info_section),
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
                    return allowed.any((b) => b == value.trim())
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
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              const SizedBox(height: 24),
              VehicleFormSectionLabel(context.l10n.vehicle_form_id_section),
              const SizedBox(height: 14),
              AppTextField(
                name: VehicleFormFields.licensePlate,
                labelText: context.l10n.vehicle_form_plate_label,
                hintText: context.l10n.vehicle_vehiclePlateHint,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                name: VehicleFormFields.vin,
                labelText: context.l10n.vehicle_vehicleVin,
                hintText: context.l10n.vehicle_vehicleVinHint,
                maxLength: 17,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppDatePicker(
                fieldName: VehicleFormFields.purchaseDate,
                labelText: context.l10n.vehicle_purchaseDate,
                lastDate: DateTime.now(),
                hintText: context.l10n.vehicle_purchaseDateHint,
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              const SizedBox(height: 24),
              const VehicleFormDocumentsSection(),
              if (onSave != null) ...[
                const SizedBox(height: 24),
                BlocBuilder<VehicleFormCubit, VehicleFormState>(
                  builder: (context, state) {
                    return AppButton(
                      onPressed: onSave,
                      isLoading: state.isLoading,
                      label: isEditing
                          ? context.l10n.vehicle_form_save
                          : context.l10n.vehicle_form_save,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}
