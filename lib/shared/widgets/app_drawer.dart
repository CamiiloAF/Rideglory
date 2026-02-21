import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/drawer_menu_item.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  Future<void> _logout(BuildContext context) async {
    context.read<AuthCubit>().signOut();
    context.read<VehicleCubit>().clearCurrentVehicle();

    context.goAndClearStack(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final vehicleCubit = context.watch<VehicleCubit>();
    final currentVehicle = vehicleCubit.currentVehicle;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      currentVehicle?.vehicleType == VehicleType.motorcycle
                          ? Icons.two_wheeler_rounded
                          : Icons.directions_car_rounded,
                      color: context.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.appName,
                    style: context.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (currentVehicle != null)
                    Text(
                      currentVehicle.name,
                      style: context.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  DrawerMenuItem(
                    icon: Icons.build_circle_outlined,
                    title: MaintenanceStrings.maintenances,
                    isSelected: currentRoute == AppRoutes.maintenances,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRoutes.maintenances) {
                        context.pushReplacementNamed(AppRoutes.maintenances);
                      }
                    },
                  ),
                  DrawerMenuItem(
                    icon: Icons.directions_car_outlined,
                    title: VehicleStrings.myVehicles,
                    isSelected: currentRoute == AppRoutes.vehicles,
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed(AppRoutes.vehicles);
                    },
                  ),
                  const Divider(height: 32),
                  DrawerMenuItem(
                    icon: Icons.explore_outlined,
                    title: EventStrings.events,
                    isSelected: currentRoute == AppRoutes.events,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRoutes.events) {
                        context.pushReplacementNamed(AppRoutes.events);
                      }
                    },
                  ),
                  DrawerMenuItem(
                    icon: Icons.event_note_outlined,
                    title: EventStrings.myEvents,
                    isSelected: currentRoute == AppRoutes.myEvents,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRoutes.myEvents) {
                        context.pushReplacementNamed(AppRoutes.myEvents);
                      }
                    },
                  ),
                  DrawerMenuItem(
                    icon: Icons.assignment_outlined,
                    title: RegistrationStrings.myRegistrations,
                    isSelected: currentRoute == AppRoutes.myRegistrations,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRoutes.myRegistrations) {
                        context.pushNamed(AppRoutes.myRegistrations);
                      }
                    },
                  ),
                  const Divider(height: 32),
                  DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    title: AppStrings.settings,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings when implemented
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppStrings.settings} ${AppStrings.comingSoon}',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: DrawerMenuItem(
                icon: Icons.logout_outlined,
                title: AuthStrings.logout,
                isSelected: false,
                textColor: context.errorColor,
                iconColor: context.errorColor,
                onTap: () {
                  ConfirmationDialog.show(
                    context: context,
                    title: AuthStrings.logoutConfirmTitle,
                    content: AuthStrings.logoutConfirmMessage,
                    cancelLabel: AppStrings.cancel,
                    confirmLabel: AuthStrings.logout,
                    confirmType: DialogActionType.danger,
                    dialogType: DialogType.warning,
                    onConfirm: () => _logout(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
