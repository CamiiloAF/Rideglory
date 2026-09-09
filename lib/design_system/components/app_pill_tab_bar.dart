import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import 'internal/pill_tab_bar_item.dart';

/// Un destino de [AppPillTabBar]. Las etiquetas visibles se resuelven desde
/// `context.l10n` en la capa que arma la lista — este componente no
/// hardcodea texto.
class AppPillTabBarDestination {
  const AppPillTabBarDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Pill Tab Bar flotante de 4 destinos: MANTENIMIENTO, EVENTOS, GARAJE, PERFIL.
///
/// Pencil: RcFXO
class AppPillTabBar extends StatelessWidget {
  const AppPillTabBar({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<AppPillTabBarDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.block,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < destinations.length; i++)
            PillTabBarItem(
              destination: destinations[i],
              selected: i == currentIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}
