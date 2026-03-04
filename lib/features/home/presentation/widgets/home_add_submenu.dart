import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/features/home/presentation/widgets/home_submenu_option.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class HomeAddSubMenu extends StatelessWidget {
  const HomeAddSubMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          HomeSubMenuOption(
            icon: Icons.two_wheeler,
            label: HomeStrings.addVehicle,
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed(AppRoutes.createVehicle);
            },
          ),
          HomeSubMenuOption(
            icon: Icons.build_circle_outlined,
            label: HomeStrings.addMaintenance,
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed(AppRoutes.createMaintenance);
            },
          ),
          HomeSubMenuOption(
            icon: Icons.calendar_month_outlined,
            label: HomeStrings.addEvent,
            onTap: () {
              Navigator.of(context).pop();
              context.pushNamed(AppRoutes.createEvent);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
