import 'package:flutter/material.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/shared/widgets/container_pull_to_refresh.dart';

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
      child: Center(child: Text(AppStrings.errorMessage(error.toString()))),
    );
  }
}
