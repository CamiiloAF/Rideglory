import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Circular icon button overlaid on the cover image (edit / delete).
class CoverOverlayButton extends StatelessWidget {
  const CoverOverlayButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.darkBgPrimary.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textOnDarkPrimary),
      ),
    );
  }
}
