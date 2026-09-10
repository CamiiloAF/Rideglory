import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Etiqueta de sección en mayúsculas ("TUS DATOS", "PERMISOS", etc.).
class RegistrationSectionLabel extends StatelessWidget {
  const RegistrationSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
      ),
    );
  }
}
