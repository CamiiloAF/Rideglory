import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_menu_divider.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_menu_item.dart';
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
          ProfileMenuItem(
            icon: Icons.event_note_outlined,
            label: context.l10n.profile_registrations,
            onTap: () => context.pushNamed(AppRoutes.myRegistrations),
          ),
          const ProfileMenuDivider(),
          ProfileMenuItem(
            icon: Icons.edit_note_rounded,
            label: context.l10n.draft_myDraftsTitle,
            onTap: () => context.pushNamed(AppRoutes.myDrafts),
          ),
          const ProfileMenuDivider(),
          ProfileMenuItem(
            icon: Icons.build_outlined,
            label: context.l10n.profile_maintenances,
            onTap: () => context.pushNamed(AppRoutes.maintenances),
          ),
          const ProfileMenuDivider(),
          ProfileMenuItem(
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
