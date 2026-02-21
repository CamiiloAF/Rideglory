import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehiclePreloadBottomSheet extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final VehicleModel? currentVehicle;

  const VehiclePreloadBottomSheet({
    super.key,
    required this.vehicles,
    this.currentVehicle,
  });

  static Future<VehicleModel?> show({
    required BuildContext context,
    required List<VehicleModel> vehicles,
    VehicleModel? currentVehicle,
  }) {
    return showModalBottomSheet<VehicleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehiclePreloadBottomSheet(
        vehicles: vehicles,
        currentVehicle: currentVehicle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    RegistrationStrings.selectVehicleToPreload,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isCurrent = vehicle.id == currentVehicle?.id;

                return ListTile(
                  leading: Icon(
                    vehicle.vehicleType == VehicleType.motorcycle
                        ? Icons.two_wheeler
                        : Icons.directions_car,
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  title: Text(vehicle.name),
                  subtitle: vehicle.brand != null || vehicle.model != null
                      ? Text(
                          [
                            vehicle.brand,
                            vehicle.model,
                          ].where((e) => e != null).join(' '),
                        )
                      : null,
                  trailing: isCurrent
                      ? Icon(
                          Icons.star,
                          size: 16,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(vehicle),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
