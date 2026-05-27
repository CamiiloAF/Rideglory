import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_detail_footer.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_plate_odo_row.dart';

class GarageVehicleContentSection extends StatelessWidget {
  const GarageVehicleContentSection({
    super.key,
    required this.vehicle,
    required this.onDetailTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GaragePlateOdoRow(vehicle: vehicle),
          const SizedBox(height: 16),
          GarageDetailFooter(onTap: onDetailTap),
        ],
      ),
    );
  }
}
