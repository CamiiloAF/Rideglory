import 'package:flutter/material.dart';

class RegistrationDetailInfoRow extends StatelessWidget {
  const RegistrationDetailInfoRow(this.label, this.value, {super.key, this.valueWidget});

  final String label;
  final String value;
  /// When non-null, shown instead of [value] (e.g. license plate tag).
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: valueWidget ??
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
