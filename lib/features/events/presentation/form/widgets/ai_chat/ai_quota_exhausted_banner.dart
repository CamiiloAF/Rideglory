import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class AiQuotaExhaustedBanner extends StatelessWidget {
  const AiQuotaExhaustedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.errorContainer.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.ai_emptyStateExhaustedSubtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
