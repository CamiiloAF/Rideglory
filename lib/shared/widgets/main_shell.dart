import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/home_bottom_navigation_bar.dart';

const int _addButtonBarIndex = 2;

int _branchIndexToBarIndex(int branchIndex) {
  if (branchIndex <= 1) return branchIndex;
  return branchIndex + 1;
}

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    this.showNotificationBadge = false,
  });

  final StatefulNavigationShell navigationShell;
  final bool showNotificationBadge;

  @override
  Widget build(BuildContext context) {
    final currentBarIndex = _branchIndexToBarIndex(navigationShell.currentIndex);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: HomeBottomNavigationBar(
        currentIndex: currentBarIndex,
        showNotificationBadge: showNotificationBadge,
        onTap: (int index) {
          if (index == _addButtonBarIndex) {
            context.pushNamed(AppRoutes.createEvent);
            return;
          }
          final branchIndex = index > _addButtonBarIndex ? index - 1 : index;
          navigationShell.goBranch(branchIndex);
        },
        onAddTap: () => context.pushNamed(AppRoutes.createEvent),
      ),
    );
  }
}
