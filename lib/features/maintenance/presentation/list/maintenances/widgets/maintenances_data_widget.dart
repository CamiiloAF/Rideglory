import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_grouped_list_item.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_section_group.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_summary_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final overdue = maintenances
        .where((m) => maintenanceStatusOf(m) == MaintenanceItemStatus.overdue)
        .toList();
    final upcoming = maintenances
        .where((m) => maintenanceStatusOf(m) == MaintenanceItemStatus.upcoming)
        .toList();
    final current = maintenances
        .where((m) => maintenanceStatusOf(m) == MaintenanceItemStatus.current)
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
  }
}
