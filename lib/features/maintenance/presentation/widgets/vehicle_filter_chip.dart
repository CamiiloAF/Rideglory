import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Chip de filtro por moto: seleccionado usa relleno oscuro (`text`) con
/// texto invertido; sin seleccionar, superficie con borde. Distinto del
/// `SuggestionChip` genérico (ese usa el acento para "seleccionado").
///
/// Pencil: `Id49n` (dentro de `V3B6C`).
class VehicleFilterChip extends StatelessWidget {
  const VehicleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
          color: selected ? colors.text : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : Border.all(color: colors.borderStrong),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? colors.bg : colors.text,
          ),
        ),
      ),
    );
  }
}
