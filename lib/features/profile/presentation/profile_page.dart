import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<AuthCubit>().signOut();
    context.read<VehicleCubit>().clearCurrentVehicle();
    context.goAndClearStack(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) context.goNamed(AppRoutes.home);
      },
      child: Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppAppBar(title: context.l10n.profile_profile),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.event_note_outlined,
                color: context.colorScheme.primary,
              ),
              title: Text(
                context.l10n.registration_myRegistrations,
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.colorScheme.onSurfaceVariant,
              ),
              onTap: () => context.pushNamed(AppRoutes.myRegistrations),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout_outlined, color: context.errorColor),
              title: Text(
                context.l10n.auth_logout,
                style: TextStyle(
                  color: context.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      ),
      ),
    );
  }
}
