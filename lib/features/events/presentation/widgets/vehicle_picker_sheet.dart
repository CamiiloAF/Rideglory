import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../domain/event_vehicle_option.dart';

/// Hoja simple para elegir una moto del garaje (EV4). Devuelve el id
/// elegido al hacer pop.
class VehiclePickerSheet extends StatelessWidget {
  const VehiclePickerSheet({
    required this.vehicles,
    required this.selectedVehicleId,
    super.key,
  });

  final List<EventVehicleOption> vehicles;
  final String selectedVehicleId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final vehicle in vehicles)
            ListTile(
              title: Text(
                vehicle.name,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: vehicle.id == selectedVehicleId
                  ? Icon(LucideIcons.check, color: colors.accent)
                  : null,
              onTap: () => Navigator.of(context).pop(vehicle.id),
            ),
        ],
      ),
    );
  }
}
