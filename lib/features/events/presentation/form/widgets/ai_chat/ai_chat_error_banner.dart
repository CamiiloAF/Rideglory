import 'package:flutter/material.dart';
import 'package:rideglory/core/exceptions/ai_domain_exceptions.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class AiChatErrorBanner extends StatelessWidget {
  const AiChatErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
  });

  final DomainException error;

  /// Null when retry is not applicable (e.g. quota_exceeded_user).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isQuotaUser = error is AiQuotaExceededUserException;

    final message = _resolveMessage(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: colorScheme.onErrorContainer, size: 18),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                ),
                if (!isQuotaUser && onRetry != null) ...[
                  AppSpacing.gapXs,
                  GestureDetector(
                    onTap: onRetry,
                    child: Text(
                      context.l10n.ai_retryButton,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveMessage(BuildContext context) {
    if (error is AiQuotaExceededUserException) {
      return context.l10n.ai_errorQuotaUser;
    }
    if (error is AiQuotaExceededProjectException) {
      return context.l10n.ai_errorQuotaProject;
    }
    if (error is AiSafetyBlockedException) {
      return context.l10n.ai_errorSafetyBlocked;
    }
    return context.l10n.ai_errorNetwork;
  }
}
