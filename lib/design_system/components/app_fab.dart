import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../tokens/app_colors.dart';

/// FAB circular del sistema. Nunca uses `FloatingActionButton` de Material
/// crudo: este es el único FAB de Rideglory.
///
/// Pencil: Q7Mkr
class AppFab extends StatelessWidget {
  const AppFab({
    required this.onPressed,
    this.icon = LucideIcons.plus,
    super.key,
  });

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: colors.accent,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: colors.shadow,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, size: 28, color: colors.onAccent),
        ),
      ),
    );
  }
}
