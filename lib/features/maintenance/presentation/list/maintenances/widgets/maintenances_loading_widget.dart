import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';

class MaintenancesLoadingWidget extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const MaintenancesLoadingWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ContainerPullToRefresh(
      onRefresh: onRefresh,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
