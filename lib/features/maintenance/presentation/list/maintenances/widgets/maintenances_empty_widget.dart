import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenancesEmptyWidget extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Future<void> Function() onActionPressed;

  const MaintenancesEmptyWidget({
    super.key,
    required this.onRefresh,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ContainerPullToRefresh(
      onRefresh: onRefresh,
      child: EmptyStateWidget(
        icon: Icons.build_circle_outlined,
        title: MaintenanceStrings.noMaintenances,
        description: MaintenanceStrings.noMaintenancesDescription,
        actionButtonText: MaintenanceStrings.addMaintenance,
        onActionPressed: onActionPressed,
      ),
    );
  }
}
