import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class MapOverlayButton extends StatelessWidget {
  const MapOverlayButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Center(child: child),
      ),
    );
  }
}
