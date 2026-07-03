import 'package:flutter/material.dart';

class AiQuotaIndicator extends StatelessWidget {
  const AiQuotaIndicator({
    super.key,
    required this.remainingQuota,
    required this.isExhausted,
    this.onTap,
  });

  final int? remainingQuota;
  final bool isExhausted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (remainingQuota == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isExhausted
              ? colorScheme.errorContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 13,
              color: isExhausted
                  ? colorScheme.onErrorContainer
                  : colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '$remainingQuota',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isExhausted
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
