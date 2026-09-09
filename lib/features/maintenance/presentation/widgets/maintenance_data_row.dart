import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Fila de dato de solo lectura del detalle: ícono, label corto y valor
/// (Taller, Costo, Nota). Sin chevron: no navega a ninguna parte.
///
/// Pencil: `Dato Taller` / `Dato Costo` / `Dato Nota` (dentro de `b8WMj1`).
class MaintenanceDataRow extends StatelessWidget {
  const MaintenanceDataRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
