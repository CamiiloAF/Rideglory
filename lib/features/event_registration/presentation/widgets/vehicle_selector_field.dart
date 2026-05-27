import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleSelectorField extends StatelessWidget {
  const VehicleSelectorField({super.key, required this.availableVehicles});

  final List<VehicleModel> availableVehicles;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<String>(
      name: RegistrationFormFields.vehicleId,
      validator: FormBuilderValidators.required(
        errorText: context.l10n.registration_vehicleBrandRequired,
      ),
      builder: (field) {
        final selectedVehicle = availableVehicles
            .where((vehicle) => vehicle.id == field.value)
            .firstOrNull;
        final displayText = selectedVehicle != null
            ? '${selectedVehicle.brand ?? ''} ${selectedVehicle.model ?? ''} - ${selectedVehicle.licensePlate ?? ''}'
                  .trim()
            : context.l10n.registration_selectVehicleToPreload;

        return GestureDetector(
          onTap: () async {
            final picked = await VehicleSelectionBottomSheet.show(
              context: context,
              vehicles: availableVehicles,
              selectedVehicleId: field.value,
            );
            if (picked != null) {
              field.didChange(picked.id);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: context.l10n.registration_vehicleData,
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
              errorText: field.errorText,
            ),
            child: Text(
              displayText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selectedVehicle != null
                    ? context.colorScheme.onSurface
                    : context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
