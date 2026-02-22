import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_list.dart';
import 'package:rideglory/shared/widgets/no_search_results_empty_widget.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/shared/widgets/form/app_search_bar.dart';

class MaintenancesDataWidget extends StatelessWidget {
  final List<MaintenanceModel> maintenances;
  final Future<void> Function() onRefresh;
  final Function(String) onSearchChanged;
  final Future<void> Function(MaintenanceModel) onTap;
  final Future<void> Function(MaintenanceModel) onEdit;
  final void Function(MaintenanceModel) onDelete;

  const MaintenancesDataWidget({
    super.key,
    required this.maintenances,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          AppSearchBar(
            hintText: MaintenanceStrings.searchMaintenances,
            onSearchChanged: onSearchChanged,
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
