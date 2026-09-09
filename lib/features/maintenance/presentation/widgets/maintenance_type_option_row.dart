import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Opción del paso 1: ícono + texto, con check cuando está seleccionada.
/// Distinto de `SuggestionChip` (ese es un chip; esto es una fila de ancho
/// completo, como la diseñó `Yhgp2`).
class MaintenanceTypeOptionRow extends StatelessWidget {
  const MaintenanceTypeOptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.accent : colors.borderStrong,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.text),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ),
            if (selected) Icon(LucideIcons.check, size: 20, color: colors.text),
          ],
        ),
      ),
    );
  }
}
