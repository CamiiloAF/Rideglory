import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class ProfileActionsList extends StatelessWidget {
  const ProfileActionsList({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<AuthCubit>().signOut();
    context.read<VehicleCubit>().clearVehicles();
    context.read<ProfileCubit>().reset();
    context.goAndClearStack(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        children: [
          _ProfileMenuItem(
            icon: Icons.event_note_outlined,
            label: context.l10n.registration_myRegistrations,
            iconColor: AppColors.textOnDarkSecondary,
            onTap: () => context.pushNamed(AppRoutes.myRegistrations),
            showChevron: true,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.darkBorderPrimary),
          _ProfileMenuItem(
            icon: Icons.build_outlined,
            label: context.l10n.maintenance_maintenances,
            iconColor: AppColors.textOnDarkSecondary,
            onTap: () => context.pushNamed(AppRoutes.maintenances),
            showChevron: true,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.darkBorderPrimary),
          _ProfileMenuItem(
            icon: Icons.logout_outlined,
            label: context.l10n.auth_logout,
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            showChevron: false,
            onTap: () {
              ConfirmationDialog.show(
                context: context,
                title: context.l10n.auth_logoutConfirmTitle,
                content: context.l10n.auth_logoutConfirmMessage,
                cancelLabel: context.l10n.cancel,
                confirmLabel: context.l10n.auth_logout,
                confirmType: DialogActionType.danger,
                dialogType: DialogType.warning,
                onConfirm: () => _logout(context),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textOnDarkSecondary,
    this.labelColor = Colors.white,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: labelColor,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textOnDarkTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
