import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
          initialValue: initialValue ?? <String, dynamic>{},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppImagePicker(
                imageUrl: state.vehicle?.imageUrl,
                localImagePath: state.localImagePath,
                onPickImage: () =>
                    context.read<VehicleFormCubit>().pickImageLocally(),
                onClearTap: state.localImagePath != null
                    ? () => context.read<VehicleFormCubit>().clearLocalImage()
                    : null,
                title: context.l10n.vehicle_uploadPhoto,
                hint: context.l10n.vehicle_selectImage,
                uploadButtonLabel: context.l10n.vehicle_uploadPhoto,
                showGenerateWithAI: false,
                labelText: context.l10n.vehicle_vehiclePhoto,
              ),
              SizedBox(height: 24),
              AppTextField(
                name: VehicleFormFields.name,
                labelText: context.l10n.vehicle_vehicleName,
                isRequired: true,
                hintText: context.l10n.vehicle_vehicleNameHint,
                prefixIcon: Icons.label,
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
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppAutocompleteField(
                      name: VehicleFormFields.brand,
                      labelText: context.l10n.vehicle_vehicleBrand,
                      hintText: context.l10n.vehicle_vehicleBrandHint,
                      suggestionsPrefixIcon: Icons.category,
                      suggestions: ColombiaMotosBrandsData.search,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        const allowed = ColombiaMotosBrandsData.brands;
                        final match = allowed.any((b) => b == value.trim());
                        return match
                            ? null
                            : context.l10n.vehicle_brandMustBeFromList;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      name: VehicleFormFields.year,
                      labelText: context.l10n.vehicle_vehicleYear,
                      hintText: context.l10n.vehicle_vehicleYearHint,
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: FormBuilderValidators.compose([
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
                          DateTime.now().year,
                          errorText: context.l10n.vehicle_invalidYear,
                          checkNullOrEmpty: false,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              AppTextField(
                name: VehicleFormFields.model,
                labelText: context.l10n.vehicle_vehicleModel,
                hintText: context.l10n.vehicle_vehicleModelHint,
                prefixIcon: Icons.style,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),

              AppMileageField(
                name: VehicleFormFields.currentMileage,
                labelText: context.l10n.vehicle_currentMileageLabel,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),

              AppTextField(
                name: VehicleFormFields.licensePlate,
                labelText: context.l10n.vehicle_vehiclePlate,
                hintText: context.l10n.vehicle_vehiclePlateHint,
                prefixIcon: Icons.confirmation_number,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),

              AppTextField(
                name: VehicleFormFields.vin,
                labelText: context.l10n.vehicle_vehicleVin,
                hintText: context.l10n.vehicle_vehicleVinHint,
                prefixIcon: Icons.pin,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 16),

              AppDatePicker(
                fieldName: VehicleFormFields.purchaseDate,
                labelText: context.l10n.vehicle_purchaseDate,
                lastDate: DateTime.now(),
                hintText: context.l10n.vehicle_purchaseDateHint,
                prefixIcon: Icon(Icons.calendar_today),
              ),
              SizedBox(height: 16),

              if (onSave != null) ...[
                SizedBox(height: 24),
                BlocBuilder<VehicleFormCubit, VehicleFormState>(
                  builder: (context, state) {
                    final isLoading = state.isLoading;
                    return AppButton(
                      onPressed: isLoading ? null : onSave,
                      label: isEditing
                          ? context.l10n.vehicle_editVehicle
                          : context.l10n.vehicle_saveVehicle,
                    );
                  },
                ),
                SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}
