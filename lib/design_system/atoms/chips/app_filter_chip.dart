import 'package:flutter/material.dart';

import '../../foundation/extensions/theme_extensions.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    final effectiveLabelStyle = (selected
            ? context.labelMedium
            : context.labelMedium)
        ?.copyWith(
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        );

    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      label: Text(label, style: effectiveLabelStyle),
      avatar: icon != null
          ? Icon(
              icon,
              size: 18,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            )
          : null,
      showCheckmark: true,
      backgroundColor: cs.surfaceContainerHighest,
      selectedColor: cs.primary,
      checkmarkColor: cs.onPrimary,
      side: BorderSide(color: cs.outlineVariant, width: 1.0),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

