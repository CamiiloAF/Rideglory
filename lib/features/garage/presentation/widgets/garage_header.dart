import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Encabezado simple de la galería: solo título, sin volver (es una
/// pestaña raíz del Pill Tab Bar).
///
/// Pencil: V02g9 › Header
class GarageHeader extends StatelessWidget {
  const GarageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        context.l10n.garage_title,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: colors.text,
        ),
      ),
    );
  }
}
