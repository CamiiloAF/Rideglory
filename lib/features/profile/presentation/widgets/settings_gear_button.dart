import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Botón de ícono que abre P1 (lista de ajustes) desde la ficha del rider.
///
/// Pencil: iFssW
class SettingsGearButton extends StatelessWidget {
  const SettingsGearButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: context.l10n.profile_settings_icon_label,
        onPressed: () => context.pushNamed(AppRoutes.profileSettings),
        icon: Icon(LucideIcons.settings, size: 20, color: colors.text),
        style: IconButton.styleFrom(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
