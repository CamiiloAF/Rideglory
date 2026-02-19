import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_checkbox.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/form/mileages_and_unit_fields.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';

class VehicleForm extends StatelessWidget {
  const VehicleForm({
    super.key,
    this.formKey,
    this.isLoading = false,
    this.isEditing = false,
    this.isOnboarding = false,
    this.isMainVehicle = false,
    this.isFirstVehicleInOnboarding = false,
    this.initialValue,
    this.onSave,
  });

  final GlobalKey<FormBuilderState>? formKey;
  final bool isLoading;
  final bool isEditing;
  final bool isOnboarding;
  final Map<String, dynamic>? initialValue;
  final VoidCallback? onSave;
  final bool isMainVehicle;
  final bool isFirstVehicleInOnboarding;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      initialValue:
          initialValue ??
          {
            VehicleFormFields.distanceUnit: DistanceUnit.kilometers,
            VehicleFormFields.vehicleType: VehicleType.motorcycle,
          },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            name: VehicleFormFields.name,
            labelText: VehicleStrings.vehicleName,
            isRequired: true,
            hintText: VehicleStrings.vehicleNameHint,
            prefixIcon: Icons.directions_car,
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

          AppDropdown<VehicleType>(
            name: VehicleFormFields.vehicleType,
            labelText: VehicleStrings.vehicleType,
            validator: FormBuilderValidators.required(
              errorText: VehicleStrings.vehicleTypeRequired,
            ),
            prefixIcon: const Icon(Icons.drive_eta),
            items: VehicleType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  name: VehicleFormFields.brand,
                  labelText: VehicleStrings.vehicleBrand,
                  hintText: VehicleStrings.vehicleBrandHint,
                  prefixIcon: Icons.local_offer,
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
          AppTextField(
            name: VehicleFormFields.model,
            labelText: VehicleStrings.vehicleModel,
            hintText: VehicleStrings.vehicleModelHint,
            prefixIcon: Icons.directions_car_filled,
          ),
          const SizedBox(height: 16),

          MileagesAndUnitFields(
            validatorsType: MileageValidatorsType.currentMileage,
            mileageFieldName: VehicleFormFields.currentMileage,
            distanceUnitFieldName: VehicleFormFields.distanceUnit,
          ),
          const SizedBox(height: 16),

          AppTextField(
            name: VehicleFormFields.licensePlate,
            labelText: VehicleStrings.vehiclePlate,
            hintText: VehicleStrings.vehiclePlateHint,
            prefixIcon: Icons.confirmation_number,
          ),
          const SizedBox(height: 16),

          AppTextField(
            name: VehicleFormFields.vin,
            labelText: VehicleStrings.vehicleVin,
            hintText: VehicleStrings.vehicleVinHint,
            prefixIcon: Icons.pin,
          ),
          const SizedBox(height: 16),

          AppDatePicker(
            fieldName: VehicleFormFields.purchaseDate,
            labelText: VehicleStrings.purchaseDate,
            lastDate: DateTime.now(),
          ),
          const SizedBox(height: 16),

          if (!isOnboarding) ...[
            AppCheckbox(
              name: VehicleFormFields.setAsCurrent,
              title: VehicleStrings.setAsMainVehicle,
              initialValue: isMainVehicle,
              enabled: !isMainVehicle,
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: isLoading ? null : onSave,
              label: isEditing
                  ? VehicleStrings.editVehicle
                  : VehicleStrings.addVehicle,
            ),
          ],

          // In onboarding, show checkbox only for first vehicle
          if (isOnboarding && isFirstVehicleInOnboarding) ...[
            AppCheckbox(
              name: VehicleFormFields.setAsCurrent,
              title: VehicleStrings.thisWillBeMainVehicle,
              initialValue: true,
              enabled: false,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
