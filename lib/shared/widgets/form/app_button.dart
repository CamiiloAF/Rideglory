import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

enum AppButtonVariant { primary, secondary, danger, success }

enum AppButtonStyle { filled, outlined, text }

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
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final appColors = context.appColors;

    final variantColor = switch (variant) {
      AppButtonVariant.primary => cs.primary,
      AppButtonVariant.secondary => cs.secondary,
      AppButtonVariant.danger => cs.error,
      AppButtonVariant.success => appColors.success,
    };

    final backgroundColor = style == AppButtonStyle.filled
        ? variantColor
        : cs.surface.withOpacity(0);

    final foregroundColor = style == AppButtonStyle.filled
        ? cs.onPrimary
        : variantColor;

    final borderColor = style == AppButtonStyle.outlined
        ? variantColor
        : cs.surface.withOpacity(0);

    final hasBorder = style == AppButtonStyle.outlined;

    final buttonWidget = Container(
      width: isFullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        border: Border.all(color: borderColor, width: hasBorder ? 1.5 : 0),
      ),
      child: Material(
        color: cs.surface.withOpacity(0),
        child: InkWell(
          onTap: onPressed == null || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding:
                padding ??
                EdgeInsets.symmetric(
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
