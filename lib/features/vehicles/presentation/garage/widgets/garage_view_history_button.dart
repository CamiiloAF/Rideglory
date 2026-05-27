import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class GarageViewHistoryButton extends StatelessWidget {
  const GarageViewHistoryButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.list,
              size: 16,
              color: AppColors.textOnDarkPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.garage_viewMaintenanceHistory,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textOnDarkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
