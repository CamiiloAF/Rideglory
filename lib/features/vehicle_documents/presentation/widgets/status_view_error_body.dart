import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Error body rendered inside [DocumentStatusView] when state is [Error].
class StatusViewErrorBody extends StatelessWidget {
  const StatusViewErrorBody({
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
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            AppSpacing.gapLg,
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
              ),
            ),
            AppSpacing.gapLg,
            AppButton(
              label: 'Reintentar',
              onPressed: onRetry,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
