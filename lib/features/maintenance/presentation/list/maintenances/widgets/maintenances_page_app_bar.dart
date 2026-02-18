import 'package:flutter/material.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

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
      title: 'Mantenimientos',
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: onFilterPressed,
              tooltip: 'Filtros',
            ),
            if (activeFilterCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$activeFilterCount',
                    style: const TextStyle(
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
          icon: const Icon(Icons.directions_car_outlined),
          onPressed: onVehiclesPressed,
          tooltip: 'Mis Vehículos',
        ),
      ],
    );
  }
}
