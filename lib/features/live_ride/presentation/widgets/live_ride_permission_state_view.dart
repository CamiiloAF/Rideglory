import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// LV1 sin permiso de ubicación: dos salidas siempre visibles, nunca una
/// pantalla vacía. `deniedForever` y `denied` comparten esta vista porque
/// ambas se resuelven igual: en los ajustes del sistema.
///
/// Pencil: J22QFC
class LiveRidePermissionStateView extends StatelessWidget {
  const LiveRidePermissionStateView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.mapPinOff, size: 28, color: colors.text),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.live_ride_permission_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.live_ride_permission_body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: context.l10n.live_ride_permission_open_settings_cta,
              icon: LucideIcons.settings,
              onPressed: Geolocator.openAppSettings,
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: context.l10n.live_ride_permission_retry_cta,
              icon: LucideIcons.refreshCw,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
