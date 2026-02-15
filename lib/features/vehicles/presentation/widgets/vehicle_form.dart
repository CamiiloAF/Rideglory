import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/form/mileages_and_unit_fields.dart';

class VehicleForm extends StatelessWidget {
  const VehicleForm({
    super.key,
    this.formKey,
    this.isLoading = false,
    this.isEditing = false,
    this.isOnboarding = false,
    this.initialValue,
    this.onSave,
  });

  final GlobalKey<FormBuilderState>? formKey;
  final bool isLoading;
  final bool isEditing;
  final bool isOnboarding;
  final Map<String, dynamic>? initialValue;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      initialValue: initialValue ?? {'distanceUnit': 'KM'},
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
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  name: 'brand',
                  labelText: 'Marca',
                  hintText: 'ej., Toyota, Ford',
                  prefixIcon: Icons.local_offer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  name: 'model',
                  labelText: 'Modelo',
                  hintText: 'ej., Camry, F-150',
                  prefixIcon: Icons.directions_car_filled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            name: 'year',
            labelText: 'Año',
            hintText: 'ej., 2020',
            prefixIcon: Icons.calendar_today,
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.numeric(errorText: 'Debe ser un número'),
              FormBuilderValidators.min(1900, errorText: 'Año inválido'),
            ]),
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isEditing ? 'Actualizar Vehículo' : 'Agregar Vehículo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
