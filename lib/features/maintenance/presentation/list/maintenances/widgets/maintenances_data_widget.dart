import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_list.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_header_view.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenancesDataWidget extends StatelessWidget {
  final List<MaintenanceModel> maintenances;
  final Future<void> Function() onRefresh;
  final Function(String) onSearchChanged;
  final Future<void> Function(MaintenanceModel) onTap;
  final Future<void> Function(MaintenanceModel) onEdit;
  final void Function(MaintenanceModel) onDelete;
  final Future<void> Function() onFilterPressed;
  final int activeFilterCount;

  const MaintenancesDataWidget({
    super.key,
    required this.maintenances,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onFilterPressed,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          MaintenancesHeaderView(
            onSearchChanged: onSearchChanged,
            onFilterPressed: onFilterPressed,
            activeFilterCount: activeFilterCount,
            maintenances: maintenances,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MaintenanceStrings.recentRecords,
                    style: context.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onFilterPressed,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colorScheme.outlineVariant, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: context.colorScheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          MaintenanceStrings.filter,
                          style: context.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: maintenances.isEmpty
                ? const NoSearchResultsEmptyWidget()
                : MaintenancesList(
                    maintenances: maintenances,
                    onTap: onTap,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
          ),
        ],
      ),
    );
  }
}
