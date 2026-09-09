import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../design_system/components/app_pill_tab_bar.dart';
import '../../l10n/l10n_extensions.dart';

/// Shell de las 4 pestañas de la app, con el Pill Tab Bar flotante encima
/// del contenido de la pestaña activa.
///
/// Pencil: RcFXO
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      AppPillTabBarDestination(
        icon: LucideIcons.wrench,
        label: context.l10n.maintenance_tab_label,
      ),
      AppPillTabBarDestination(
        icon: LucideIcons.calendarDays,
        label: context.l10n.events_tab_label,
      ),
      AppPillTabBarDestination(
        icon: LucideIcons.bike,
        label: context.l10n.garage_tab_label,
      ),
      AppPillTabBarDestination(
        icon: LucideIcons.user,
        label: context.l10n.profile_tab_label,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: AppPillTabBar(
            destinations: destinations,
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}
