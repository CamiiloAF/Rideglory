import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// Floating SOS button shown on the live map.
/// Tapping opens the SOS confirmation sheet.
class SosButton extends StatelessWidget {
  const SosButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.55),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
