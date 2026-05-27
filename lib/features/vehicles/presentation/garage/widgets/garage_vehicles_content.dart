import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_empty_state.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_main_vehicle_card.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_maintenance_widget.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_other_vehicle_item.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_other_vehicles_section_header.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class GarageVehiclesContent extends StatelessWidget {
  const GarageVehiclesContent({
    super.key,
    required this.loadVehicles,
    required this.onSelectVehicle,
    required this.onMaintenanceCreated,
    required this.onMaintenanceRefreshRequested,
    this.openWithVehicleId,
  });

  final Future<void> Function() loadVehicles;
  final ValueChanged<VehicleModel> onSelectVehicle;
  final ValueChanged<MaintenanceModel> onMaintenanceCreated;
  final ValueChanged<String> onMaintenanceRefreshRequested;
  final String? openWithVehicleId;

  Future<void> _addVehicle(BuildContext context) async {
    final result = await context.pushNamed(AppRoutes.createVehicle);
    if (!context.mounted || result == null) return;
    context.read<VehicleCubit>().fetchMyVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VehicleCubit>().state;
    final vehicles = state is Data<List<VehicleModel>>
        ? state.data.where((v) => !v.isArchived).toList(growable: false)
        : const <VehicleModel>[];

    if (vehicles.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              GarageHeader(onAdd: () => _addVehicle(context)),
              Expanded(
                child: GarageEmptyState(
                  onVehicleSavedLocally: ([_]) => loadVehicles(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final mainVehicle = vehicles.firstWhere(
      (v) => v.isMainVehicle,
      orElse: () => vehicles.first,
    );
    final otherVehicles = vehicles
        .where((v) => v.id != mainVehicle.id)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.darkCard,
          onRefresh: loadVehicles,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GarageHeader(onAdd: () => _addVehicle(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GarageMainVehicleCard(
                      vehicle: mainVehicle,
                      onTap: () => onSelectVehicle(mainVehicle),
                      onOptionsTap: () => GarageOptionsBottomSheet.show(
                        context,
                        mainVehicle,
                        onGarageListUpdatedLocally: ([_]) => loadVehicles(),
                        onMaintenanceCreated: onMaintenanceCreated,
                        onMaintenanceRefreshRequested:
                            onMaintenanceRefreshRequested,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GarageMaintenanceWidget(
                      vehicle: mainVehicle,
                      onViewHistoryTap: () => context.pushNamed(
                        AppRoutes.maintenances,
                        extra: mainVehicle.id,
                      ),
                    ),
                    if (otherVehicles.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      GarageOtherVehiclesSectionHeader(count: otherVehicles.length),
                      const SizedBox(height: 12),
                      ...otherVehicles.map(
                        (vehicle) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GarageOtherVehicleItem(
                            vehicle: vehicle,
                            onTap: () => onSelectVehicle(vehicle),
                            onOptionsTap: () => GarageOptionsBottomSheet.show(
                              context,
                              vehicle,
                              onGarageListUpdatedLocally: ([_]) =>
                                  loadVehicles(),
                              onMaintenanceCreated: onMaintenanceCreated,
                              onMaintenanceRefreshRequested:
                                  onMaintenanceRefreshRequested,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
