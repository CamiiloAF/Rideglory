import 'package:flutter/material.dart';

import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';

/// Entrada grande de kilometraje del paso 2: cifra destacada + "km", con
/// el teclado numérico nativo (Pencil `x74Sa` no dibuja un teclado propio,
/// solo el del sistema operativo).
class MaintenanceOdometerInput extends StatelessWidget {
  const MaintenanceOdometerInput({
    required this.controller,
    required this.suffixLabel,
    super.key,
  });

  final TextEditingController controller;
  final String suffixLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderStrong),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            suffixLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
