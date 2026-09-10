import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'sos_coordinates_card.dart';

/// LV7 con SOS abierto: la rodada terminó pero el SOS propio sigue activo
/// (D19: un SOS abierto sigue visible tras terminar la rodada, nunca lo
/// cierra el fin del evento).
///
/// Pencil: NdP2O
class LiveRideFinishedWithSosView extends StatelessWidget {
  const LiveRideFinishedWithSosView({
    required this.lat,
    required this.lng,
    required this.onCloseSos,
    required this.onBackToEvent,
    super.key,
    this.accuracyM,
  });

  final double lat;
  final double lng;
  final double? accuracyM;
  final VoidCallback onCloseSos;
  final VoidCallback onBackToEvent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(width: double.infinity, height: 8, color: colors.errorSolid),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.flag,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.live_ride_finished_status_line,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: colors.border,
                ),
                const SizedBox(height: 16),
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: colors.errorSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.siren,
                    size: 26,
                    color: colors.errorText,
                  ),
                ),
                Text(
                  context.l10n.live_ride_finished_sos_title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.live_ride_finished_sos_body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SosCoordinatesCard(lat: lat, lng: lng, accuracyM: accuracyM),
                const SizedBox(height: 16),
                AppSecondaryButton(
                  label: context.l10n.sos_close_cta,
                  icon: LucideIcons.check,
                  destructive: true,
                  onPressed: onCloseSos,
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  label: context.l10n.live_ride_finished_cta,
                  onPressed: onBackToEvent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
