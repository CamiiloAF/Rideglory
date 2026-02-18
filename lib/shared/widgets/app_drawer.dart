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
                  colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
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
                      color: const Color(0xFF6366F1),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RideGlory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (currentVehicle != null)
                    Text(
                      currentVehicle.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
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
                    title: 'Mantenimientos',
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
                    title: 'Mis Vehículos',
                    isSelected: currentRoute == AppRoutes.vehicles,
                    onTap: () {
                      Navigator.pop(context);
                      context.pushNamed(AppRoutes.vehicles);
                    },
                  ),
                  const Divider(height: 32),
                  DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings when implemented
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuración próximamente'),
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
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: DrawerMenuItem(
                icon: Icons.logout_outlined,
                title: 'Cerrar sesión',
                isSelected: false,
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await AppDialogHelper.showConfirmation(
                    context: context,
                    title: 'Cerrar sesión',
                    content: '¿Estás seguro de que deseas cerrar sesión?',
                    cancelLabel: 'Cancelar',
                    confirmLabel: 'Cerrar sesión',
                    confirmType: DialogActionType.danger,
                    dialogType: DialogType.warning,
                  );

                  if (confirm == true && context.mounted) {
                    _logout(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
