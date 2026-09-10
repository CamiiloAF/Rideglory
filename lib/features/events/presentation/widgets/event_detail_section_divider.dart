import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Separador de 1dp entre secciones del detalle.
class EventDetailSectionDivider extends StatelessWidget {
  const EventDetailSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(height: 1, color: colors.border);
  }
}
