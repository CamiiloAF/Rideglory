import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class NotificationsErrorState extends StatelessWidget {
  const NotificationsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            AppSpacing.gapLg,
            Text(
              context.l10n.notification_loadError,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              context.l10n.notification_loadErrorSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
              ),
            ),
            AppSpacing.gapLg,
            AppButton(
              label: context.l10n.notification_retry,
              onPressed: onRetry,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
