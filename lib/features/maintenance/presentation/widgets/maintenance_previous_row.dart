import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Fila de un registro anterior del mismo tipo, en el detalle: kilometraje
/// + fecha a la izquierda, cuánto duró a la derecha.
///
/// Pencil: `Anterior N` (dentro de `Card anteriores`).
class MaintenancePreviousRow extends StatelessWidget {
  const MaintenancePreviousRow({
    required this.odometerLabel,
    required this.dateLabel,
    this.durationLabel,
    this.onTap,
    super.key,
  });

  final String odometerLabel;
  final String dateLabel;
  final String? durationLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    odometerLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (durationLabel != null)
              Text(
                durationLabel!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
