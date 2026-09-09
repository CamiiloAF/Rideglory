import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/settings_row.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/profile.dart';
import '../cubit/profile_settings_cubit.dart';
import '../cubit/sign_out_cubit.dart';
import '../legal_links.dart';
import 'settings_card.dart';
import 'settings_notifications_card.dart';
import 'settings_section_label.dart';

/// Contenido de P1 con el perfil ya cargado: cinco grupos de ajustes.
///
/// Pencil: BS3wJ
class SettingsListContent extends StatelessWidget {
  const SettingsListContent({
    required this.profile,
    required this.notificationsEnabled,
    required this.analyticsEnabled,
    super.key,
  });

  final Profile profile;
  final bool notificationsEnabled;
  final bool analyticsEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        SettingsSectionLabel(context.l10n.profile_section_account),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.user,
              label: context.l10n.profile_field_name,
              value: profile.fullName?.isNotEmpty == true
                  ? profile.fullName
                  : null,
              onTap: () =>
                  context.pushNamed(AppRoutes.profileEdit, extra: profile),
            ),
            SettingsRow(
              icon: LucideIcons.mail,
              label: context.l10n.profile_field_email,
              value: profile.email,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsSectionLabel(context.l10n.profile_section_emergency),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.phone,
              label: context.l10n.profile_emergency_contact_label,
              value: profile.hasEmergencyContact
                  ? profile.emergencyContactName
                  : context.l10n.profile_emergency_not_configured,
              onTap: () => context.pushNamed(AppRoutes.profileEmergencyContact),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsSectionLabel(context.l10n.profile_section_notifications),
        SettingsNotificationsCard(
          notificationsEnabled: notificationsEnabled,
          analyticsEnabled: analyticsEnabled,
          onNotificationsChanged: (value) => context
              .read<ProfileSettingsCubit>()
              .setNotificationsEnabled(value),
          onAnalyticsChanged: (value) =>
              context.read<ProfileSettingsCubit>().setAnalyticsEnabled(value),
        ),
        const SizedBox(height: 18),
        SettingsSectionLabel(context.l10n.profile_section_legal),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.fileText,
              label: context.l10n.profile_terms,
              onTap: () => launchUrl(
                Uri.parse(LegalLinks.terms),
                mode: LaunchMode.externalApplication,
              ),
            ),
            SettingsRow(
              icon: LucideIcons.shield,
              label: context.l10n.profile_privacy,
              onTap: () => launchUrl(
                Uri.parse(LegalLinks.privacy),
                mode: LaunchMode.externalApplication,
              ),
            ),
            SettingsRow(
              icon: LucideIcons.checkCheck,
              label: context.l10n.profile_my_consents,
              onTap: () => context.pushNamed(AppRoutes.profileConsents),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsCard(
          children: [
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
      ],
    );
  }
}
