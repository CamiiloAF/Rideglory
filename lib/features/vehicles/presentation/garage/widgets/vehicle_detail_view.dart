import 'package:flutter/material.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_full_specs_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_garage_overview_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_quick_info_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart';

class VehicleDetailView extends StatelessWidget {
  const VehicleDetailView({
    super.key,
    required this.vehicle,
    required this.index,
    required this.totalVehicles,
    required this.totalMileage,
    required this.onAddVehicle,
    required this.onOptionsTap,
  });

  final VehicleModel vehicle;
  final int index;
  final int totalVehicles;
  final int totalMileage;
  final VoidCallback onAddVehicle;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Details Bottom Sheet
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E), // Darker surface matching the mockup
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VehicleDetailHeader(
                vehicle: vehicle,
                onAddVehicle: onAddVehicle,
                onOptionsTap: onOptionsTap,
              ),
              const SizedBox(height: 32),
              VehicleQuickInfoSection(vehicle: vehicle),
              const SizedBox(height: 32),
              VehicleFullSpecsSection(vehicle: vehicle),
              const SizedBox(height: 32),
              VehicleMaintenanceHistorySection(vehicle: vehicle),
              const SizedBox(height: 32),
              VehicleGarageOverviewSection(
                totalVehicles: totalVehicles,
                totalMileage: totalMileage,
              ),
              // Bottom padding for the navigation bar
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
