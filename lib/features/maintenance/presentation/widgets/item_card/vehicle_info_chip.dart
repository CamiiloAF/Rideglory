import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class VehicleInfoChip extends StatelessWidget {
  final VehicleModel vehicle;

  const VehicleInfoChip({super.key, required this.vehicle});

  IconData get _vehicleIcon {
    return vehicle.vehicleType == VehicleType.car
        ? Icons.directions_car_rounded
        : Icons.two_wheeler_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_vehicleIcon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            vehicle.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          if (vehicle.brand != null) ...[
            const SizedBox(width: 4),
            Text(
              '• ${vehicle.brand}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
