import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/widgets/active_events_block_sheet.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_analytics_optout_tile.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_menu_divider.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_menu_item.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Event states that still block account deletion while the user organizes
/// them (AC1/AC2/AC4/AC12 of the account-deletion precondition).
const _activeOrganizerEventStates = {
  EventState.draft,
  EventState.scheduled,
  EventState.inProgress,
};

class ProfileActionsList extends StatelessWidget {
  const ProfileActionsList({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<AuthCubit>().signOut();
    context.read<VehicleCubit>().clearVehicles();
    context.read<ProfileCubit>().reset();
    context.goAndClearStack(AppRoutes.login);
  }

  /// Re-checks (never cached — AC4) whether the current user is still
  /// organizing active events before allowing entry to the delete-account
  /// flow. Blocks with [ActiveEventsBlockSheet] when there is at least one;
  /// on a fetch failure, shows feedback and does NOT navigate (avoids a
  /// silent bypass of the precondition).
  Future<void> _handleDeleteAccountTap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorMessage = context.l10n.profile_deleteAccountBlocked_checkError;
    final result = await getIt<GetMyEventsUseCase>()();
    if (!context.mounted) return;

    result.fold(
      (error) {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      },
      (events) {
        final activeEvents = events
            .where((event) => _activeOrganizerEventStates.contains(event.state))
            .toList();
        if (activeEvents.isEmpty) {
          context.pushNamed(AppRoutes.deleteAccount);
        } else {
          ActiveEventsBlockSheet.show(
            context: context,
            activeEvents: activeEvents,
          );
        }
      },
    );
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
            icon: Icons.build_outlined,
            label: context.l10n.profile_maintenances,
            onTap: () => context.pushNamed(AppRoutes.maintenances),
          ),
          const ProfileMenuDivider(),
          const ProfileAnalyticsOptOutTile(),
          const ProfileMenuDivider(),
          ProfileMenuItem(
            icon: Icons.delete_outline,
            label: context.l10n.profile_deleteAccount_menuItem,
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            showChevron: false,
            onTap: () => _handleDeleteAccountTap(context),
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
                icon: Icons.logout,
                onConfirm: () => _logout(context),
              );
            },
          ),
        ],
      ),
    );
  }
}
