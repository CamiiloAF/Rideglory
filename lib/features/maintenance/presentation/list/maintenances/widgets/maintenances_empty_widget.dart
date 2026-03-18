import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
        title: context.l10n.maintenance_noMaintenances,
        description: context.l10n.maintenance_noMaintenancesDescription,
        actionButtonText: context.l10n.maintenance_addMaintenance,
        onActionPressed: onActionPressed,
      ),
    );
  }
}
