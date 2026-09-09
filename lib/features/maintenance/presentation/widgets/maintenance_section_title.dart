import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Título de sección en mayúsculas ("PRÓXIMOS", "HISTORIAL", el mes de un
/// grupo del historial).
class MaintenanceSectionTitle extends StatelessWidget {
  const MaintenanceSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: colors.textSecondary,
      ),
    );
  }
}
