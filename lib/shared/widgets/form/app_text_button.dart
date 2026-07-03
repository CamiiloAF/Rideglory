import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
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
  final String? analyticsTapEvent;
  final Map<String, Object>? analyticsTapParams;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppTextButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.iconSize = 18,
    this.visualDensity,
    this.analyticsTapEvent,
    this.analyticsTapParams,
  });

  VoidCallback? _wrapWithAnalytics(VoidCallback? callback) {
    if (callback == null || isLoading) return null;
    final tapEvent = analyticsTapEvent;
    if (tapEvent == null) return callback;
    return () {
      getIt<AnalyticsService>().logEvent(tapEvent, analyticsTapParams).ignore();
      callback();
    };
  }

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
        onPressed: _wrapWithAnalytics(onPressed),
        icon: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: AppLoadingIndicator(
                  variant: AppLoadingIndicatorVariant.inline,
                  color: foregroundColor,
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
      onPressed: _wrapWithAnalytics(onPressed),
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        visualDensity: visualDensity,
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: AppLoadingIndicator(
                variant: AppLoadingIndicatorVariant.inline,
                color: foregroundColor,
              ),
            )
          : Text(label),
    );
  }
}
