import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

enum AppTextButtonVariant { primary, muted, danger }

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppTextButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double iconSize;
  final VisualDensity? visualDensity;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppTextButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.iconSize = 18,
    this.visualDensity,
  });

  Color get _foregroundColor {
    switch (variant) {
      case AppTextButtonVariant.primary:
        return AppColors.primary;
      case AppTextButtonVariant.muted:
        return Colors.grey[600]!;
      case AppTextButtonVariant.danger:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed == null || isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
                ),
              )
            : Icon(icon, size: iconSize),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: _foregroundColor,
          visualDensity: visualDensity,
        ),
      );
    }

    return TextButton(
      onPressed: onPressed == null || isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _foregroundColor,
        visualDensity: visualDensity,
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
              ),
            )
          : Text(label),
    );
  }
}
