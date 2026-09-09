import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Contenedor de un grupo de [SettingsRow]/[AppSwitchTile] con divisores,
/// tal como agrupa "CUENTA", "LEGAL", etc. en P1/P2.
///
/// Pencil: BS3wJ, iFssW
class SettingsCard extends StatelessWidget {
  const SettingsCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Container(height: 1, color: colors.border));
      }
      rows.add(children[i]);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        color: colors.surface,
        child: Column(children: rows),
      ),
    );
  }
}
