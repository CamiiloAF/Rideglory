import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenancesErrorWidget extends StatelessWidget {
  final String error;
  final Future<void> Function() onRefresh;

  const MaintenancesErrorWidget({
    super.key,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ContainerPullToRefresh(
      onRefresh: onRefresh,
      child: Center(child: Text(context.l10n.errorMessage(error.toString()))),
    );
  }
}
