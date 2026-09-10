import 'package:flutter/material.dart';

import '../../../../design_system/components/vehicle_selector.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/event_vehicle_option.dart';
import 'vehicle_picker_sheet.dart';

/// Selector de moto de EV4, sobre las motos del garaje del rider.
class RegistrationVehicleField extends StatelessWidget {
  const RegistrationVehicleField({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onSelected,
    super.key,
  });

  final List<EventVehicleOption> vehicles;
  final String? selectedVehicleId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) return const SizedBox.shrink();
    final selected = vehicles.firstWhere(
      (vehicle) => vehicle.id == selectedVehicleId,
      orElse: () => vehicles.first,
    );
    final model = selected.model?.trim();
    final name = (model != null && model.isNotEmpty)
        ? '${selected.brand} $model'
        : selected.name;
    final plate = selected.licensePlate?.trim().isNotEmpty ?? false
        ? selected.licensePlate!
        : context.l10n.events_register_no_vehicle_plate;
    return VehicleSelector(
      vehicleName: name,
      plateAndMileage: plate,
      imageUrl: selected.imageUrl,
      onTap: () async {
        final pickedId = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => VehiclePickerSheet(
            vehicles: vehicles,
            selectedVehicleId: selected.id,
          ),
        );
        if (pickedId != null) onSelected(pickedId);
      },
    );
  }
}
