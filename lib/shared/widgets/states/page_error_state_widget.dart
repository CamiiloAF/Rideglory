import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class PageErrorStateWidget extends StatelessWidget {
  const PageErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onRefresh,
  });

  final String title;
  final String message;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return ContainerPullToRefresh(
      onRefresh: onRefresh,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: context.colorScheme.error,
              ),
              AppSpacing.gapLg,
              Text(
                title,
                style: context.titleMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapSm,
              Text(
                message,
                style: context.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                AppSpacing.gapLg,
                AppButton(
                  label: context.l10n.retry,
                  onPressed: onRetry!,
                  icon: Icons.refresh,
                  isFullWidth: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
