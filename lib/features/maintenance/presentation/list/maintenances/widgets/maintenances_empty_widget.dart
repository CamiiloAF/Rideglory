import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';

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
        title: 'No hay mantenimientos registrados',
        description: 'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo',
        iconColor: const Color(0xFF6366F1),
        actionButtonText: 'Agregar mantenimiento',
        onActionPressed: onActionPressed,
      ),
    );
  }
}
