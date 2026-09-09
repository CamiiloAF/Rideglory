import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// El único switch de la app. Nunca uses `Switch`, `SwitchListTile`,
/// `CupertinoSwitch` ni `FormBuilderSwitch`.
///
/// Pencil: c1ny5S
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: value ? colors.accent : colors.border,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            // Sobre el amarillo el knob va oscuro; apagado usa el texto
            // inverso de superficie para mantenerse legible en ambos temas.
            color: value ? colors.onAccent : colors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
