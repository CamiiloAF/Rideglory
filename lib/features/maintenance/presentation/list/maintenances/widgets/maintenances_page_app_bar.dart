import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenancesPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int activeFilterCount;
  final VoidCallback onFilterPressed;
  final VoidCallback onVehiclesPressed;

  const MaintenancesPageAppBar({
    super.key,
    required this.activeFilterCount,
    required this.onFilterPressed,
    required this.onVehiclesPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppAppBar(
      title: context.l10n.maintenance_maintenances,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.filter_list_rounded),
              onPressed: onFilterPressed,
              tooltip: context.l10n.maintenance_filters,
            ),
            if (activeFilterCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$activeFilterCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.directions_car_outlined),
          onPressed: onVehiclesPressed,
          tooltip: context.l10n.maintenance_myVehicles,
        ),
      ],
    );
  }
}
