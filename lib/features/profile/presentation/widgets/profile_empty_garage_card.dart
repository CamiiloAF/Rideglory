import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class ProfileEmptyGarageCard extends StatelessWidget {
  const ProfileEmptyGarageCard({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.darkBgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: AppColors.textOnDarkTertiary,
                size: 24,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.add,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
