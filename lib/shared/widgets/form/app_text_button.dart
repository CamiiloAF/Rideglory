import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    final foregroundColor = switch (variant) {
      AppTextButtonVariant.primary => cs.primary,
      AppTextButtonVariant.muted => cs.onSurfaceVariant,
      AppTextButtonVariant.danger => cs.error,
    };

    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed == null || isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: const AppLoadingIndicator(
                  variant: AppLoadingIndicatorVariant.inline,
                ),
              )
            : Icon(icon, size: iconSize, color: foregroundColor),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          visualDensity: visualDensity,
        ),
      );
    }

    return TextButton(
      onPressed: onPressed == null || isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        visualDensity: visualDensity,
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: AppLoadingIndicator(
                variant: AppLoadingIndicatorVariant.inline,
              ),
            )
          : Text(label),
    );
  }
}
