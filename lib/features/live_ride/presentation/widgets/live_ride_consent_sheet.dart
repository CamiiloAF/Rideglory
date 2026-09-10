import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'internal/live_ride_consent_row.dart';

/// LV2: aviso previo propio antes del diálogo del sistema (D21, prominent
/// disclosure). Se muestra **solo** al pulsar "Compartir mi ubicación",
/// nunca al abrir la pantalla. Devuelve `true` si el rider pulsó
/// "Permitir".
///
/// Pencil: iJUhj
class LiveRideConsentSheet extends StatelessWidget {
  const LiveRideConsentSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const LiveRideConsentSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.live_ride_consent_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 14),
            LiveRideConsentRow(
              icon: LucideIcons.users,
              text: context.l10n.live_ride_consent_row_participants,
            ),
            const SizedBox(height: 14),
            LiveRideConsentRow(
              icon: LucideIcons.clock,
              text: context.l10n.live_ride_consent_row_duration,
            ),
            const SizedBox(height: 14),
            LiveRideConsentRow(
              icon: LucideIcons.square,
              text: context.l10n.live_ride_consent_row_stop,
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: context.l10n.live_ride_consent_allow_cta,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: context.l10n.live_ride_consent_dismiss_cta,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
