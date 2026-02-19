import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';

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
        iconColor: const Color(0xFF6366F1),
        actionButtonText: MaintenanceStrings.addMaintenance,
        onActionPressed: onActionPressed,
      ),
    );
  }
}
