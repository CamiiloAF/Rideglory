import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
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
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_archived_section.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_other_vehicles_section_header.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class _NoActiveVehiclesNotice extends StatelessWidget {
  const _NoActiveVehiclesNotice({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkTertiary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.garage_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.vehicle_noActiveVehicles,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.vehicle_noActiveVehiclesSubtitle,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add, color: AppColors.darkBgPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final allVehicles = state is Data<List<VehicleModel>>
        ? state.data
        : const <VehicleModel>[];
    final activeVehicles =
        allVehicles.where((v) => !v.isArchived).toList(growable: false);
    final archivedVehicles =
        allVehicles.where((v) => v.isArchived).toList(growable: false);

    if (activeVehicles.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: SafeArea(
          bottom: false,
          child: archivedVehicles.isEmpty
              ? Column(
                  children: [
                    GarageHeader(onAdd: () => _addVehicle(context)),
                    Expanded(
                      child: GarageEmptyState(
                        onRefresh: loadVehicles,
                        onVehicleSavedLocally: ([_]) => loadVehicles(),
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
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
                            _NoActiveVehiclesNotice(
                              onAdd: () => _addVehicle(context),
                            ),
                            const SizedBox(height: 20),
                            GarageArchivedSection(
                              key: const ValueKey('garage-archived-section'),
                              archivedVehicles: archivedVehicles,
                              initiallyExpanded: true,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final mainVehicle = activeVehicles.firstWhere(
      (v) => v.isMainVehicle,
      orElse: () => activeVehicles.first,
    );
    final otherVehicles = activeVehicles
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
                      GarageOtherVehiclesSectionHeader(
                        count: otherVehicles.length,
                      ),
                      const SizedBox(height: 12),
                      ...otherVehicles.map(
                        (vehicle) => Padding(
                          key: ValueKey(vehicle.id),
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
                    GarageArchivedSection(
                      key: const ValueKey('garage-archived-section'),
                      archivedVehicles: archivedVehicles,
                    ),
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
