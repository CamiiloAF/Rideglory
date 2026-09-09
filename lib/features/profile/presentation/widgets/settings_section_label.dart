import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Encabezado de sección de ajustes ("CUENTA", "LEGAL", etc.).
///
/// Pencil: BS3wJ
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
