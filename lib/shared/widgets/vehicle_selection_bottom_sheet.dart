import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/vehicle_list_item.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleSelectionBottomSheet extends StatelessWidget {
  final String? subtitle;
  final List<VehicleModel> vehicles;
  final String? selectedVehicleId;

  const VehicleSelectionBottomSheet({
    super.key,
    this.subtitle,
    required this.vehicles,
    this.selectedVehicleId,
  });

  static Future<VehicleModel?> show({
    required BuildContext context,
    String? subtitle,
    required List<VehicleModel> vehicles,
    String? selectedVehicleId,
  }) {
    return showModalBottomSheet<VehicleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleSelectionBottomSheet(
        subtitle: subtitle,
        vehicles: vehicles,
        selectedVehicleId: selectedVehicleId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar vehículo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          // Vehicles list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isSelected = vehicle.id == selectedVehicleId;

                return VehicleListItem(
                  vehicle: vehicle,
                  isSelected: isSelected,
                  onTap: () => Navigator.pop(context, vehicle),
                );
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
