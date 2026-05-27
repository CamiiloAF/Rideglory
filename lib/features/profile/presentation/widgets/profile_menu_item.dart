import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textOnDarkSecondary,
    this.labelColor = AppColors.textOnDarkPrimary,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: labelColor,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textOnDarkTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
