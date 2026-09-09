import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_switch_tile.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'settings_card.dart';

/// Card "NOTIFICACIONES Y DATOS" de P1: dos switches, uno por preferencia
/// de dispositivo.
///
/// Pencil: BS3wJ
class SettingsNotificationsCard extends StatelessWidget {
  const SettingsNotificationsCard({
    required this.notificationsEnabled,
    required this.analyticsEnabled,
    required this.onNotificationsChanged,
    required this.onAnalyticsChanged,
    super.key,
  });

  final bool notificationsEnabled;
  final bool analyticsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onAnalyticsChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(LucideIcons.bell, size: 20, color: colors.text),
              const SizedBox(width: 12),
              Expanded(
                child: AppSwitchTile(
                  label: context.l10n.profile_notifications_label,
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(LucideIcons.barChart3, size: 20, color: colors.text),
              const SizedBox(width: 12),
              Expanded(
                child: AppSwitchTile(
                  label: context.l10n.profile_share_usage_label,
                  subtitle: context.l10n.profile_share_usage_subtitle,
                  value: analyticsEnabled,
                  onChanged: onAnalyticsChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
