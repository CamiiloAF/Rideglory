import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenanceNextServiceRow extends StatelessWidget {
  final String label;
  final String value;

  const MaintenanceNextServiceRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
