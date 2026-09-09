import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/vehicle_option.dart';
import 'vehicle_filter_chip.dart';

/// Fila de chips "Todas" + una por moto, para filtrar la agenda y el
/// historial de la pantalla principal.
///
/// Pencil: `Id49n`.
class VehicleFilterRow extends StatelessWidget {
  const VehicleFilterRow({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onSelected,
    super.key,
  });

  final List<VehicleOption> vehicles;
  final String? selectedVehicleId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          VehicleFilterChip(
            label: context.l10n.maintenance_filter_all,
            selected: selectedVehicleId == null,
            onTap: () => onSelected(null),
          ),
          for (final vehicle in vehicles) ...[
            const SizedBox(width: 8),
            VehicleFilterChip(
              label: vehicle.chipLabel,
              selected: selectedVehicleId == vehicle.id,
              onTap: () => onSelected(vehicle.id),
            ),
          ],
        ],
      ),
    );
  }
}
