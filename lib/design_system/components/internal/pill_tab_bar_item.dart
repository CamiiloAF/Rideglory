import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../app_pill_tab_bar.dart';

/// Un destino individual dentro de [AppPillTabBar].
class PillTabBarItem extends StatelessWidget {
  const PillTabBarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AppPillTabBarDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                destination.icon,
                size: 22,
                color: selected ? colors.onAccent : colors.onBlockSecondary,
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Text(
                  destination.label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: colors.onAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
