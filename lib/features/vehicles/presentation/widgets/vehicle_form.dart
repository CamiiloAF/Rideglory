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
            'distanceUnit': DistanceUnit.kilometers,
            'vehicleType': VehicleType.motorcycle,
          },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            name: 'name',
            labelText: 'Nombre del vehículo',
            isRequired: true,
            hintText: 'ej., Mi Auto, Camioneta Familiar',
            prefixIcon: Icons.directions_car,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'El nombre es requerido',
              ),
              FormBuilderValidators.minLength(
                3,
                errorText: 'Mínimo 3 caracteres',
              ),
            ]),
          ),
          const SizedBox(height: 16),

          AppDropdown<VehicleType>(
            name: 'vehicleType',
            labelText: 'Tipo de vehículo',
            validator: FormBuilderValidators.required(
              errorText: 'El tipo de vehículo es requerido',
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
                  name: 'brand',
                  labelText: 'Marca',
                  hintText: 'ej., Toyota',
                  prefixIcon: Icons.local_offer,
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  name: 'year',
                  labelText: 'Año',
                  hintText: 'ej., 2020',
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.numeric(
                      errorText: 'Debe ser un número',
                      checkNullOrEmpty: false,
                    ),
                    FormBuilderValidators.min(
                      1900,
                      errorText: 'Año inválido',
                      checkNullOrEmpty: false,
                    ),
                    FormBuilderValidators.max(
                      DateTime.now().year,
                      errorText: 'Año inválido',
                      checkNullOrEmpty: false,
                    ),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            name: 'model',
            labelText: 'Modelo',
            hintText: 'ej., Camry',
            prefixIcon: Icons.directions_car_filled,
          ),
          const SizedBox(height: 16),

          MileagesAndUnitFields(
            validatorsType: MileageValidatorsType.currentMileage,
            mileageFieldName: 'currentMileage',
            distanceUnitFieldName: 'distanceUnit',
          ),
          const SizedBox(height: 16),

          AppTextField(
            name: 'licensePlate',
            labelText: 'Placa',
            hintText: 'ej., ABC-1234',
            prefixIcon: Icons.confirmation_number,
          ),
          const SizedBox(height: 16),

          AppTextField(
            name: 'vin',
            labelText: 'VIN',
            hintText: 'Número de Identificación del Vehículo',
            prefixIcon: Icons.pin,
          ),
          const SizedBox(height: 16),

          AppDatePicker(
            fieldName: 'purchaseDate',
            labelText: 'Fecha de compra',
            lastDate: DateTime.now(),
          ),
          const SizedBox(height: 16),

          if (!isOnboarding) ...[
            AppCheckbox(
              name: 'setAsCurrent',
              title: 'Establecer como vehículo principal',
              initialValue: isMainVehicle,
              enabled: !isMainVehicle,
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: isLoading ? null : onSave,
              label: isEditing ? 'Actualizar Vehículo' : 'Agregar Vehículo',
            ),
          ],

          // In onboarding, show checkbox only for first vehicle
          if (isOnboarding && isFirstVehicleInOnboarding) ...[
            AppCheckbox(
              name: 'setAsCurrent',
              title: 'Este será tu vehículo principal',
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
