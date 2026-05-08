import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class PageLoadingStateWidget extends StatelessWidget {
  const PageLoadingStateWidget({super.key, this.onRefresh});

  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return ContainerPullToRefresh(
      onRefresh: onRefresh,
      child: const AppLoadingIndicator(
        variant: AppLoadingIndicatorVariant.page,
      ),
    );
  }
}
