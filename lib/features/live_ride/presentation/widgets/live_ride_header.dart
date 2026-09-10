import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/sharing_status.dart';
import 'internal/live_ride_header_circle_button.dart';

/// Header flotante de LV1/LV1b: volver, nombre de la rodada, icono de
/// riders (solo organizador, D23: accesible desde aquí) y la fila de
/// estado — chip "Compartiendo ubicación" + Detener, o el CTA amarillo
/// "Compartir mi ubicación" cuando todavía no comparte.
///
/// Pencil: GzYAP (compartiendo) / uIOZR (LV1b, sin compartir)
class LiveRideHeader extends StatelessWidget {
  const LiveRideHeader({
    required this.eventName,
    required this.sharing,
    required this.isOwner,
    required this.onBack,
    required this.onShare,
    required this.onStop,
    required this.onViewRiders,
    super.key,
  });

  final String eventName;
  final SharingStatus sharing;
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onStop;
  final VoidCallback onViewRiders;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isSharing =
        sharing == SharingStatus.sharing || sharing == SharingStatus.stopping;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: colors.plate,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              LiveRideHeaderCircleButton(
                icon: LucideIcons.arrowLeft,
                background: colors.plateChip,
                foreground: colors.plateText,
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  eventName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.plateText,
                  ),
                ),
              ),
              if (isOwner) ...[
                const SizedBox(width: 12),
                LiveRideHeaderCircleButton(
                  icon: LucideIcons.users,
                  background: colors.plateChip,
                  foreground: colors.plateText,
                  onPressed: onViewRiders,
                  tooltip: context.l10n.live_ride_riders_header_action,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (isSharing)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.plateChip,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.successOnBlock,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.l10n.live_ride_sharing_chip,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: colors.plateText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppPrimaryButton(
                  label: context.l10n.live_ride_stop_cta,
                  icon: LucideIcons.square,
                  destructive: true,
                  compact: true,
                  onPressed: sharing == SharingStatus.stopping ? null : onStop,
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: sharing == SharingStatus.requestingPermission
                    ? null
                    : onShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  disabledBackgroundColor: colors.accent.withValues(alpha: 0.5),
                  foregroundColor: colors.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  LucideIcons.mapPin,
                  size: 18,
                  color: colors.onAccent,
                ),
                label: Text(
                  context.l10n.live_ride_share_cta,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
