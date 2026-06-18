import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class ProfileErrorState extends StatelessWidget {
  const ProfileErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final DomainException error;
  final Future<void> Function() onRetry;

  Future<void> _logout(BuildContext context) async {
    context.read<AuthCubit>().signOut();
    context.read<VehicleCubit>().clearVehicles();
    context.read<ProfileCubit>().reset();
    context.goAndClearStack(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.colorScheme.error,
                ),
                AppSpacing.gapLg,
                Text(
                  context.l10n.profile_loadingError,
                  style: context.titleMedium,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapSm,
                Text(
                  error.message,
                  style: context.bodySmall,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapLg,
                AppButton(
                  label: context.l10n.retry,
                  onPressed: onRetry,
                  icon: Icons.refresh,
                  isFullWidth: false,
                ),
              ],
            ),
          ),
          AppButton(
            label: context.l10n.auth_logout,
            onPressed: () {
              ConfirmationDialog.show(
                context: context,
                title: context.l10n.auth_logoutConfirmTitle,
                content: context.l10n.auth_logoutConfirmMessage,
                cancelLabel: context.l10n.cancel,
                confirmLabel: context.l10n.auth_logout,
                confirmType: DialogActionType.danger,
                icon: Icons.logout,
                onConfirm: () => _logout(context),
              );
            },
            variant: AppButtonVariant.ghost,
            icon: Icons.logout_outlined,
          ),
        ],
      ),
    );
  }
}
