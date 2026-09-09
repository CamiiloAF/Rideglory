import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Fila "Ver X más" / "Ver menos" al pie de la lista de anteriores.
class MaintenanceSeeMoreRow extends StatelessWidget {
  const MaintenanceSeeMoreRow({
    required this.label,
    required this.expanded,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
              color: colors.text,
            ),
          ],
        ),
      ),
    );
  }
}
