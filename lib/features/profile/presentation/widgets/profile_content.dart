import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_switch.dart';
import '../../../../design_system/components/settings_row.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/profile.dart';
import '../cubit/profile_overview_cubit.dart';
import '../cubit/profile_settings_cubit.dart';
import '../cubit/sign_out_cubit.dart';
import 'profile_emergency_banner.dart';
import 'profile_identity_card.dart';
import 'profile_vehicles_row.dart';
import 'settings_card.dart';
import 'settings_section_label.dart';

/// Contenido de P2 con datos ya cargados: identidad, emergencia, motos y el
/// bloque corto de ajustes.
///
/// Pencil: iFssW
class ProfileContent extends StatelessWidget {
  const ProfileContent({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final vehiclesState = context.watch<ProfileOverviewCubit>().state.vehicles;
    final notificationsEnabled = context
        .watch<ProfileSettingsCubit>()
        .state
        .notificationsEnabled;

    return ListView(
      children: [
        ProfileIdentityCard(
          profile: profile,
          onTap: () => context.pushNamed(AppRoutes.profileEdit, extra: profile),
        ),
        if (!profile.hasEmergencyContact) ...[
          const SizedBox(height: 12),
          ProfileEmergencyBanner(
            onAddContact: () =>
                context.pushNamed(AppRoutes.profileEmergencyContact),
          ),
        ],
        const SizedBox(height: 18),
        SettingsSectionLabel(context.l10n.profile_my_vehicles_title),
        ProfileVehiclesRow(vehiclesState: vehiclesState),
        const SizedBox(height: 18),
        SettingsSectionLabel(context.l10n.profile_settings_group_title),
        SettingsCard(
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(LucideIcons.bell, size: 20, color: colors.text),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.profile_notifications_label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                    ),
                    AppSwitch(
                      value: notificationsEnabled,
                      onChanged: (value) => context
                          .read<ProfileSettingsCubit>()
                          .setNotificationsEnabled(value),
                    ),
                  ],
                ),
              ),
            ),
            SettingsRow(
              icon: LucideIcons.shield,
              label: context.l10n.profile_privacy_and_consents,
              onTap: () => context.pushNamed(AppRoutes.profileConsents),
            ),
            SettingsRow(
              icon: LucideIcons.logOut,
              label: context.l10n.profile_sign_out,
              onTap: () => context.read<SignOutCubit>().signOut(),
            ),
            SettingsRow(
              icon: LucideIcons.trash2,
              iconColor: colors.errorSolid,
              label: context.l10n.profile_delete_account,
              onTap: () => context.pushNamed(AppRoutes.profileDeleteAccount),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
