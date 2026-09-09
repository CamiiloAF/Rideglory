import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Chip de sugerencia seleccionable (ej. tipos de mantenimiento frecuentes).
///
/// Pencil: d8N9d
class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.accent : colors.borderStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}
