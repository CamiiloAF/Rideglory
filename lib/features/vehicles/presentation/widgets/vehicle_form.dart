import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/shared/widgets/form/app_image_picker.dart';
import 'package:rideglory/shared/widgets/form/app_autocomplete_field.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_mileage_field.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';

class VehicleForm extends StatelessWidget {
  const VehicleForm({
    super.key,
    this.formKey,
    this.isLoading = false,
    this.isEditing = false,
    this.initialValue,
    this.onSave,
  });

  final GlobalKey<FormBuilderState>? formKey;
  final bool isLoading;
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
                title: VehicleStrings.uploadPhoto,
                hint: VehicleStrings.selectImage,
                uploadButtonLabel: VehicleStrings.uploadPhoto,
                showGenerateWithAI: false,
                labelText: VehicleStrings.vehiclePhoto,
              ),
              const SizedBox(height: 24),
              AppTextField(
                name: VehicleFormFields.name,
                labelText: VehicleStrings.vehicleName,
                isRequired: true,
                hintText: VehicleStrings.vehicleNameHint,
                prefixIcon: Icons.label,
                textInputAction: TextInputAction.next,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: VehicleStrings.nameRequired,
                  ),
                  FormBuilderValidators.minLength(
                    3,
                    errorText: VehicleStrings.minCharacters,
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppAutocompleteField(
                      name: VehicleFormFields.brand,
                      labelText: VehicleStrings.vehicleBrand,
                      hintText: VehicleStrings.vehicleBrandHint,
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
                            : VehicleStrings.brandMustBeFromList;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      name: VehicleFormFields.year,
                      labelText: VehicleStrings.vehicleYear,
                      hintText: VehicleStrings.vehicleYearHint,
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.numeric(
                          errorText: AppStrings.mustBeNumber,
                          checkNullOrEmpty: false,
                        ),
                        FormBuilderValidators.min(
                          1900,
                          errorText: VehicleStrings.invalidYear,
                          checkNullOrEmpty: false,
                        ),
                        FormBuilderValidators.max(
                          DateTime.now().year,
                          errorText: VehicleStrings.invalidYear,
                          checkNullOrEmpty: false,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const AppTextField(
                name: VehicleFormFields.model,
                labelText: VehicleStrings.vehicleModel,
                hintText: VehicleStrings.vehicleModelHint,
                prefixIcon: Icons.style,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              const AppMileageField(
                name: VehicleFormFields.currentMileage,
                labelText: VehicleStrings.currentMileageLabel,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              const AppTextField(
                name: VehicleFormFields.licensePlate,
                labelText: VehicleStrings.vehiclePlate,
                hintText: VehicleStrings.vehiclePlateHint,
                prefixIcon: Icons.confirmation_number,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              const AppTextField(
                name: VehicleFormFields.vin,
                labelText: VehicleStrings.vehicleVin,
                hintText: VehicleStrings.vehicleVinHint,
                prefixIcon: Icons.pin,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              AppDatePicker(
                fieldName: VehicleFormFields.purchaseDate,
                labelText: VehicleStrings.purchaseDate,
                lastDate: DateTime.now(),
                hintText: VehicleStrings.purchaseDateHint,
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),

              if (onSave != null) ...[
                const SizedBox(height: 24),
                AppButton(
                  onPressed: isLoading ? null : onSave,
                  label: isEditing
                      ? VehicleStrings.editVehicle
                      : VehicleStrings.saveVehicle,
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
