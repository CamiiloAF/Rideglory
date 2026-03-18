import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenancesLoadingWidget extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const MaintenancesLoadingWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ContainerPullToRefresh(
      onRefresh: onRefresh,
      child: AppLoadingIndicator(variant: AppLoadingIndicatorVariant.page),
    );
  }
}
