import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// Visual variants for [AppCircleIconButton].
///
/// - [surface]: dark card background; default for in-app-bar / leading actions.
/// - [accent]: orange primary background; foreground uses `colorScheme.onPrimary`
///   (matching `AppButton` filled-primary). Use for CTA-style circular triggers
///   like the "+" in the maintenance list.
/// - [translucent]: semi-transparent dark; for overlays on top of images.
enum AppCircleIconButtonVariant { surface, accent, translucent }

/// 36×36 circular icon button. Single source of truth for leading back arrows
/// and small circular trigger buttons across the app.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.variant = AppCircleIconButtonVariant.surface,
    this.hasBorder = false,
    this.surfaceColor,
  });

  /// Convenience factory for the default "back" leading button.
  const AppCircleIconButton.back({
    super.key,
    required this.onTap,
    this.hasBorder = false,
    this.surfaceColor,
  }) : icon = Icons.arrow_back,
       variant = AppCircleIconButtonVariant.surface;

  final IconData icon;
  final VoidCallback onTap;
  final AppCircleIconButtonVariant variant;
  final bool hasBorder;

  /// Override the surface background. Only honored when
  /// [variant] is [AppCircleIconButtonVariant.surface].
  final Color? surfaceColor;

  static const double _size = 40;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (variant) {
      AppCircleIconButtonVariant.surface => (
        surfaceColor ?? AppColors.darkCard,
        AppColors.textOnDarkPrimary,
      ),
      AppCircleIconButtonVariant.accent => (
        AppColors.primary,
        colorScheme.onPrimary,
      ),
      AppCircleIconButtonVariant.translucent => (
        AppColors.darkBgPrimary.withValues(alpha: 0.6),
        AppColors.textOnDarkPrimary,
      ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: hasBorder
              ? Border.all(color: AppColors.darkBorderPrimary, width: 1)
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: foreground, size: _iconSize),
      ),
    );
  }
}
