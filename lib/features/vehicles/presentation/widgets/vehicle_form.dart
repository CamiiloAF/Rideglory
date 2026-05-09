import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/form/form_image_section.dart';

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
              BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
                builder: (context, imageState) {
                  final imageData = imageState.whenOrNull(data: (data) => data);
                  return FormImageSection(
                    imageUrl: imageData?.hasLocalImage == true
                        ? null
                        : imageData?.displayImageUrl,
                    localImagePath: imageData?.hasLocalImage == true
                        ? imageData?.displayImageUrl
                        : null,
                    onPickImage: () =>
                        context.read<FormImageCubit>().pickImageFromGallery(),
                    onClearTap: imageData?.hasLocalImage == true
                        ? context.read<FormImageCubit>().clearLocalImage
                        : null,
                    title: context.l10n.vehicle_uploadPhoto,
                    hint: context.l10n.vehicle_selectImage,
                    uploadButtonLabel: context.l10n.vehicle_uploadPhoto,
                    showGenerateWithAI: false,
                    labelText: context.l10n.vehicle_vehiclePhoto,
                  );
                },
              ),
              AppSpacing.gapXxl,
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
              AppSpacing.gapLg,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppAutocompleteField(
                      name: VehicleFormFields.brand,
                      labelText: context.l10n.vehicle_vehicleBrand,
                      isRequired: true,
                      hintText: context.l10n.vehicle_vehicleBrandHint,
                      suggestionsPrefixIcon: Icons.category,
                      suggestions: ColombiaMotosBrandsData.search,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: context.l10n.vehicle_brandRequired,
                        ),
                        (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          const allowed = ColombiaMotosBrandsData.brands;
                          final match = allowed.any((b) => b == value.trim());
                          return match
                              ? null
                              : context.l10n.vehicle_brandMustBeFromList;
                        },
                      ]),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: AppTextField(
                      name: VehicleFormFields.year,
                      labelText: context.l10n.vehicle_vehicleYear,
                      isRequired: true,
                      hintText: context.l10n.vehicle_vehicleYearHint,
                      prefixIcon: Icons.calendar_today,
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
                ],
              ),
              AppSpacing.gapLg,
              AppTextField(
                name: VehicleFormFields.model,
                labelText: context.l10n.vehicle_vehicleModel,
                hintText: context.l10n.vehicle_vehicleModelHint,
                prefixIcon: Icons.style,
                isRequired: true,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.vehicle_modelRequired,
                  ),
                ]),
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapLg,

              AppMileageField(
                name: VehicleFormFields.currentMileage,
                labelText: context.l10n.vehicle_currentMileageLabel,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapLg,

              AppTextField(
                name: VehicleFormFields.licensePlate,
                labelText: context.l10n.vehicle_vehiclePlate,
                hintText: context.l10n.vehicle_vehiclePlateHint,
                prefixIcon: Icons.confirmation_number,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapLg,

              AppTextField(
                name: VehicleFormFields.vin,
                labelText: context.l10n.vehicle_vehicleVin,
                hintText: context.l10n.vehicle_vehicleVinHint,
                prefixIcon: Icons.pin,
                maxLength: 17,
                textInputAction: TextInputAction.done,
              ),
              AppSpacing.gapLg,

              AppDatePicker(
                fieldName: VehicleFormFields.purchaseDate,
                labelText: context.l10n.vehicle_purchaseDate,
                lastDate: DateTime.now(),
                hintText: context.l10n.vehicle_purchaseDateHint,
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              AppSpacing.gapLg,

              if (onSave != null) ...[
                AppSpacing.gapXxl,
                BlocBuilder<VehicleFormCubit, VehicleFormState>(
                  builder: (context, state) {
                    final isLoading = state.isLoading;
                    return AppButton(
                      onPressed: onSave,
                      isLoading: isLoading,
                      label: isEditing
                          ? context.l10n.vehicle_editVehicle
                          : context.l10n.vehicle_saveVehicle,
                    );
                  },
                ),
                AppSpacing.gapLg,
              ],
            ],
          ),
        );
      },
    );
  }
}
