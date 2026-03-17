import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class RegistrationDetailPersonalField extends StatelessWidget {
  const RegistrationDetailPersonalField({
    super.key,
    required this.label,
    required this.value,
    this.valueWidget,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = context.textTheme;
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget ??
            Text(
              value,
              style: theme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
