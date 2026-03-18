import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/bottom_nav_add_button.dart';
import 'package:rideglory/shared/widgets/bottom_nav_item.dart';

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
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Inicio',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            BottomNavItem(
              icon: Icons.directions_car_outlined,
              activeIcon: Icons.directions_car,
              label: 'Garaje',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            BottomNavAddButton(onTap: onAddTap),
            BottomNavItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              label: 'Eventos',
              isActive: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            BottomNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Perfil',
              isActive: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}
