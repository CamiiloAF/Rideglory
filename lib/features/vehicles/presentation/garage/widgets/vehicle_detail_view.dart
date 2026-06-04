import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_hero_image.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_identification_card.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_nav.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_specs_card.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_top_row.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_maintenance_history_section.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_kind.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart';

class VehicleDetailView extends StatelessWidget {
  const VehicleDetailView({
    super.key,
    required this.vehicle,
    required this.onBack,
    required this.maintenanceRefreshTick,
    required this.onPendingMaintenanceConsumed,
    required this.onMaintenanceCreated,
    required this.onMaintenanceRefreshRequested,
    this.pendingCreatedMaintenance,
    this.onVehicleUpdated,
  });

  final VehicleModel vehicle;
  final VoidCallback onBack;
  final int maintenanceRefreshTick;
  final MaintenanceModel? pendingCreatedMaintenance;
  final void Function(String vehicleId) onPendingMaintenanceConsumed;
  final ValueChanged<MaintenanceModel> onMaintenanceCreated;
  final ValueChanged<String> onMaintenanceRefreshRequested;
  final ValueChanged<VehicleModel>? onVehicleUpdated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: VehicleDetailNav(vehicle: vehicle, onBack: onBack),
          ),
          SliverToBoxAdapter(
            child: VehicleDetailHeroImage(vehicle: vehicle),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                VehicleDetailTopRow(vehicle: vehicle),
                const SizedBox(height: 16),
                if (vehicle.licensePlate != null || vehicle.vin != null) ...[
                  VehicleDetailIdentificationCard(vehicle: vehicle),
                  const SizedBox(height: 16),
                ],
                VehicleDetailSpecsCard(vehicle: vehicle),
                const SizedBox(height: 16),
                VehicleDocumentCard(
                  kind: VehicleDocumentKind.soat,
                  vehicle: vehicle,
                ),
                const SizedBox(height: 16),
                VehicleMaintenanceHistorySection(
                  vehicle: vehicle,
                  maintenanceRefreshTick: maintenanceRefreshTick,
                  pendingCreatedMaintenance: pendingCreatedMaintenance,
                  onPendingMaintenanceConsumed: onPendingMaintenanceConsumed,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
