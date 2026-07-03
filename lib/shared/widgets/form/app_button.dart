import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/design_system.dart';

enum AppButtonVariant {
  primary,
  secondary,
  danger,
  success,
  ghost,
  ghostSubtle,
}

enum AppButtonStyle { filled, outlined, tonal, text }

enum AppButtonShape { rounded, pill }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final AppButtonShape shape;
  final String? analyticsTapEvent;
  final Map<String, Object>? analyticsTapParams;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.style = AppButtonStyle.filled,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.padding,
    this.width,
    this.height = 48,
    this.shape = AppButtonShape.rounded,
    this.analyticsTapEvent,
    this.analyticsTapParams,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final appColors = context.appColors;

    final isDisabled = onPressed == null && !isLoading;

    // ghost/ghostSubtle use fixed dark fill (#242429) regardless of style.
    if (variant == AppButtonVariant.ghost ||
        variant == AppButtonVariant.ghostSubtle) {
      final baseForeground = variant == AppButtonVariant.ghost
          ? AppColors.textOnDarkPrimary
          : AppColors.textOnDarkSecondary;
      final foregroundColor = isDisabled
          ? baseForeground.withValues(alpha: 0.38)
          : baseForeground;
      final buttonWidget = Container(
        width: isFullWidth ? double.infinity : width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            shape == AppButtonShape.pill ? 25.0 : 8.0,
          ),
          color: isDisabled
              ? AppColors.darkTertiary.withValues(alpha: 0.5)
              : AppColors.darkTertiary,
        ),
        child: Material(
          color: cs.surface.withValues(alpha: 0),
          child: InkWell(
            onTap: onPressed == null || isLoading
                ? null
                : () {
                    final tapEvent = analyticsTapEvent;
                    if (tapEvent != null) {
                      getIt<AnalyticsService>()
                          .logEvent(tapEvent, analyticsTapParams)
                          .ignore();
                    }
                    onPressed!();
                  },
            borderRadius: BorderRadius.circular(
              shape == AppButtonShape.pill ? 25.0 : 8.0,
            ),
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(
                    vertical: AppSize.sm,
                    horizontal: AppSize.md,
                  ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoadingIndicator(
                          variant: AppLoadingIndicatorVariant.inline,
                          color: foregroundColor,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: foregroundColor, size: 20),
                            AppSpacing.hGapSm,
                          ],
                          Flexible(
                            child: Text(
                              label,
                              style: context.labelLarge?.copyWith(
                                color: foregroundColor,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
      return buttonWidget;
    }

    final variantColor = switch (variant) {
      AppButtonVariant.primary => cs.primary,
      AppButtonVariant.secondary => cs.secondary,
      AppButtonVariant.danger => cs.error,
      AppButtonVariant.success => appColors.success,
      _ => cs.primary,
    };

    final backgroundColor = isDisabled
        ? cs.onSurface.withValues(alpha: 0.12)
        : switch (style) {
            AppButtonStyle.filled => variantColor,
            // Soft/tonal fill: the variant color at low opacity, no border.
            AppButtonStyle.tonal => variantColor.withValues(alpha: 0.1),
            _ => cs.surface.withValues(alpha: 0),
          };

    final foregroundColor = isDisabled
        ? cs.onSurface.withValues(alpha: 0.38)
        : style == AppButtonStyle.filled
        ? cs.onPrimary
        : variantColor;

    final borderColor = (!isDisabled && style == AppButtonStyle.outlined)
        ? variantColor
        : cs.surface.withValues(alpha: 0);

    final hasBorder = style == AppButtonStyle.outlined;

    final radius = shape == AppButtonShape.pill ? 25.0 : 8.0;

    final buttonWidget = Container(
      width: isFullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: hasBorder ? 1.5 : 0),
      ),
      child: Material(
        color: cs.surface.withValues(alpha: 0),
        child: InkWell(
          onTap: onPressed == null || isLoading
              ? null
              : () {
                  final tapEvent = analyticsTapEvent;
                  if (tapEvent != null) {
                    getIt<AnalyticsService>()
                        .logEvent(tapEvent, analyticsTapParams)
                        .ignore();
                  }
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  vertical: AppSize.sm,
                  horizontal: AppSize.md,
                ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: AppLoadingIndicator(
                        variant: AppLoadingIndicatorVariant.inline,
                        color: foregroundColor,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: foregroundColor, size: 20),
                          AppSpacing.hGapSm,
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: context.labelLarge?.copyWith(
                              color: foregroundColor,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return buttonWidget;
  }
}
