import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Nota de promedio de duración entre servicios ("Te dura X km en
/// promedio."), debajo de la lista de anteriores.
class MaintenanceAverageNote extends StatelessWidget {
  const MaintenanceAverageNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.trendingUp, size: 15, color: colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
