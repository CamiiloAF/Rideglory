import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/features/profile/constants/profile_strings.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

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
      appBar: const AppAppBar(title: ProfileStrings.profile),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout_outlined, color: context.errorColor),
              title: Text(
                AuthStrings.logout,
                style: TextStyle(
                  color: context.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          ],
        ),
      ),
      ),
    );
  }
}
