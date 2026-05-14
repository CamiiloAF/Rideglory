import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/shared/widgets/bottom_nav_add_button.dart';
import 'package:rideglory/shared/widgets/bottom_nav_item.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class HomeBottomNavigationBar extends StatelessWidget {
  const HomeBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
    this.showNotificationBadge = false,
  });

  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddTap;
  final bool showNotificationBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 21,
        right: 21,
        top: 12,
        bottom: 21 + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.tabBarBackground,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            BottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: context.l10n.nav_inicio,
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            BottomNavItem(
              icon: Icons.directions_car_outlined,
              activeIcon: Icons.directions_car,
              label: context.l10n.nav_garaje,
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            BottomNavAddButton(onTap: onAddTap),
            BottomNavItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              label: context.l10n.nav_eventos,
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            BottomNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: context.l10n.nav_perfil,
              isActive: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}
