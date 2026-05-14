import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_full_specs_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_garage_overview_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_quick_info_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailView extends StatelessWidget {
  const VehicleDetailView({
    super.key,
    required this.vehicle,
    required this.index,
    required this.totalVehicles,
    required this.totalMileage,
    required this.onAddVehicle,
    required this.onOptionsTap,
    required this.isMainVehicle,
    required this.maintenanceRefreshTick,
    required this.onPendingMaintenanceConsumed,
    this.pendingCreatedMaintenance,
    this.onMainVehicleChanged,
  });

  final VehicleModel vehicle;
  final int index;
  final int totalVehicles;
  final int totalMileage;
  final VoidCallback onAddVehicle;
  final VoidCallback onOptionsTap;
  final bool isMainVehicle;
  final int maintenanceRefreshTick;
  final MaintenanceModel? pendingCreatedMaintenance;
  final void Function(String vehicleId) onPendingMaintenanceConsumed;
  final ValueChanged<bool>? onMainVehicleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Details Bottom Sheet
        Container(
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
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
                isMainVehicle: isMainVehicle,
                onMainVehicleChanged: onMainVehicleChanged,
              ),
              AppSpacing.gapXxxl,
              VehicleQuickInfoSection(vehicle: vehicle),
              AppSpacing.gapXxxl,
              VehicleFullSpecsSection(vehicle: vehicle),
              AppSpacing.gapXxxl,
              VehicleMaintenanceHistorySection(
                vehicle: vehicle,
                maintenanceRefreshTick: maintenanceRefreshTick,
                pendingCreatedMaintenance: pendingCreatedMaintenance,
                onPendingMaintenanceConsumed: onPendingMaintenanceConsumed,
              ),
              AppSpacing.gapXxxl,
              VehicleGarageOverviewSection(
                totalVehicles: totalVehicles,
                totalMileage: totalMileage,
              ),
              // Bottom padding for the navigation bar
              AppSpacing.gapXxxl,
            ],
          ),
        ),
      ],
    );
  }
}
