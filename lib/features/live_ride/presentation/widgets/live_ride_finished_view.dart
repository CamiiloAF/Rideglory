import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// LV7: la rodada terminó y el rider no tiene un SOS propio abierto.
///
/// Pencil: OQJZS
class LiveRideFinishedView extends StatelessWidget {
  const LiveRideFinishedView({required this.onBackToEvent, super.key});

  final VoidCallback onBackToEvent;

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
              child: Icon(LucideIcons.flag, size: 28, color: colors.text),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.live_ride_finished_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.live_ride_finished_body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: context.l10n.live_ride_finished_cta,
              onPressed: onBackToEvent,
            ),
          ],
        ),
      ),
    );
  }
}
