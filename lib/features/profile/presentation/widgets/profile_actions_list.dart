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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.event_note_outlined,
            color: colorScheme.primary,
          ),
          title: Text(
            context.l10n.registration_myRegistrations,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
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
    );
  }
}
