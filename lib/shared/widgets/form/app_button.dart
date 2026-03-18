import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

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
  final EdgeInsets padding;
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
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    this.width,
    this.height = 48,
  });

  Color get _variantColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.danger:
        return AppColors.error;
      case AppButtonVariant.success:
        return AppColors.success;
    }
  }

  Color get _backgroundColor =>
      style == AppButtonStyle.filled ? _variantColor : Colors.transparent;

  Color get _foregroundColor =>
      style == AppButtonStyle.filled ? Colors.white : _variantColor;

  Color get _borderColor =>
      style == AppButtonStyle.outlined ? _variantColor : Colors.transparent;

  bool get _hasBorder => style == AppButtonStyle.outlined;

  @override
  Widget build(BuildContext context) {
    final buttonWidget = Container(
      width: isFullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _backgroundColor,
        border: Border.all(color: _borderColor, width: _hasBorder ? 1.5 : 0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed == null || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: padding,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _foregroundColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: _foregroundColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: context.labelLarge?.copyWith(
                              color: _foregroundColor,
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
