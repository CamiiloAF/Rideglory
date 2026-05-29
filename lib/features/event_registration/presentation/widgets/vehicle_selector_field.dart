import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_card.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_placeholder_card.dart';
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

        Future<void> openPicker() async {
          final picked = await VehicleSelectionBottomSheet.show(
            context: context,
            vehicles: availableVehicles,
            selectedVehicleId: field.value,
          );
          if (picked != null) {
            field.didChange(picked.id);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedVehicle != null)
              VehicleSelectorCard(
                vehicle: selectedVehicle,
                onChange: openPicker,
              )
            else
              VehicleSelectorPlaceholderCard(onTap: openPicker),
            if (field.errorText != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  field.errorText!,
                  style: context.bodySmall?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
