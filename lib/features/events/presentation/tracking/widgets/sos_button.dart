import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// Floating SOS button shown on the live map.
/// Tapping opens the SOS confirmation sheet.
class SosButton extends StatelessWidget {
  const SosButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.tracking_sosSemanticsLabel,
      button: true,
      child: GestureDetector(
        // Always tappable: when active, tapping asks to confirm cancelling SOS.
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isActive ? Colors.transparent : AppColors.error,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: AppColors.error, width: 3)
                : null,
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
              style: TextStyle(
                color: isActive ? AppColors.error : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
