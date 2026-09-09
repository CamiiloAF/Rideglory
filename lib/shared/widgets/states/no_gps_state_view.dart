import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../design_system/components/app_primary_button.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../l10n/l10n_extensions.dart';

/// Estado propio de esta app: GPS del dispositivo apagado.
class NoGpsStateView extends StatelessWidget {
  const NoGpsStateView({required this.onOpenLocationSettings, super.key});

  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.navigationOff, size: 40, color: colors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.l10n.common_no_gps_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.common_no_gps_body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: context.l10n.common_no_gps_action,
              onPressed: onOpenLocationSettings,
            ),
          ],
        ),
      ),
    );
  }
}
