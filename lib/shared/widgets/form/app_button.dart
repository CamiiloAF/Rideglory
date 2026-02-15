import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
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
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    this.width,
    this.height,
  });

  Color get _backgroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return const Color(0xFF6366F1);
      case AppButtonVariant.secondary:
        return const Color(0xFF8B5CF6);
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        return Colors.white;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return const Color(0xFF6366F1);
    }
  }

  Color get _borderColor {
    switch (variant) {
      case AppButtonVariant.outline:
        return Colors.grey[300]!;
      default:
        return Colors.transparent;
    }
  }

  BoxShadow? get _shadow {
    if (variant == AppButtonVariant.primary ||
        variant == AppButtonVariant.secondary) {
      return BoxShadow(
        color: _backgroundColor.withValues(alpha: .3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidget = Container(
      width: isFullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _backgroundColor,
        border: Border.all(
          color: _borderColor,
          width: variant == AppButtonVariant.outline ? 1.5 : 0,
        ),
        boxShadow: _shadow != null ? [_shadow!] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed == null || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_foregroundColor),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: _foregroundColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: _foregroundColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
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
