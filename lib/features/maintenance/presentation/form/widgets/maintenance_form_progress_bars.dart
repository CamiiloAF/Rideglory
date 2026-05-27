import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

/// Progress bar indicators shown below the maintenance form header.
/// Currently displays two filled bars representing the single form step.
class MaintenanceFormProgressBars extends StatelessWidget {
  const MaintenanceFormProgressBars({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
