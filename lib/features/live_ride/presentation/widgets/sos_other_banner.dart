import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../live_ride_labels.dart';

/// Banner rojo persistente encima del mapa cuando otro rider de la
/// rodada tiene un SOS activo (LV5a). Nunca se puede descartar sin
/// resolverlo: solo "Ver" hacia la tarjeta con las acciones.
///
/// Pencil: KkFzQ
class SosOtherBanner extends StatelessWidget {
  const SosOtherBanner({
    required this.riderName,
    required this.distanceMeters,
    required this.onView,
    super.key,
  });

  final String riderName;
  final double distanceMeters;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final distance = liveRideDistanceLabel(context, distanceMeters);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colors.errorSolid,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(LucideIcons.siren, size: 18, color: colors.onBlock),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.sos_other_banner_title(riderName, distance),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.onBlock,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onView,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.onBlock,
                foregroundColor: colors.errorSolid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                context.l10n.sos_other_banner_cta,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
