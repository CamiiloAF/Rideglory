import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_section_group.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_summary_widget.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class MaintenancesDataWidget extends StatelessWidget {
  final List<MaintenanceModel> maintenances;
  final Future<void> Function() onRefresh;
  final Future<void> Function(MaintenanceModel) onTap;
  final Future<void> Function() onFilterPressed;
  final Future<void> Function() onAddPressed;

  const MaintenancesDataWidget({
    super.key,
    required this.maintenances,
    required this.onRefresh,
    required this.onTap,
    required this.onFilterPressed,
    required this.onAddPressed,
  });

  static const _successColor = Color(0xFF22C55E);
  static const _warningColor = Color(0xFFEAB308);

  int _vehicleMileage(BuildContext context) {
    final vehicleCubit = context.read<VehicleCubit>();
    final maintenancesCubit = context.read<MaintenancesCubit>();
    // Use the vehicle from the single-vehicle filter if set
    final vehicleIds = maintenancesCubit.filters.vehicleIds;
    if (vehicleIds.length == 1) {
      try {
        return vehicleCubit.availableVehicles
            .firstWhere((v) => v.id == vehicleIds.first)
            .currentMileage;
      } catch (_) {}
    }
    return vehicleCubit.currentMileage ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
      builder: (context, _) {
        final currentMileage = _vehicleMileage(context);
        final overdue = maintenances
            .where(
              (m) => maintenanceStatusOf(m, currentMileage) == MaintenanceItemStatus.overdue,
            )
            .toList();
        final upcoming = maintenances
            .where(
              (m) => maintenanceStatusOf(m, currentMileage) == MaintenanceItemStatus.upcoming,
            )
            .toList();
        final current = maintenances
            .where(
              (m) =>
                  maintenanceStatusOf(m, currentMileage) == MaintenanceItemStatus.current ||
                  maintenanceStatusOf(m, currentMileage) == MaintenanceItemStatus.completed,
            )
            .toList();

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: maintenances.isEmpty
              ? const NoSearchResultsEmptyWidget()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MaintenanceSummaryWidget(maintenances: maintenances),
                            const SizedBox(height: 8),
                            MaintenanceSectionGroup(
                              label: context.l10n.maintenance_overdue_section,
                              accentColor: AppColors.error,
                              items: overdue,
                              status: MaintenanceItemStatus.overdue,
                              onTap: onTap,
                            ),
                            MaintenanceSectionGroup(
                              label: context.l10n.maintenance_upcoming_section,
                              accentColor: _warningColor,
                              items: upcoming,
                              status: MaintenanceItemStatus.upcoming,
                              onTap: onTap,
                            ),
                            MaintenanceSectionGroup(
                              label: context.l10n.maintenance_on_track_section,
                              accentColor: _successColor,
                              items: current,
                              status: MaintenanceItemStatus.current,
                              onTap: onTap,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
