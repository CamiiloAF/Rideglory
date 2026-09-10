import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Tarjeta de coordenadas + precisión, compartida por LV4a/LV4b y LV7 con
/// SOS abierto.
class SosCoordinatesCard extends StatelessWidget {
  const SosCoordinatesCard({
    required this.lat,
    required this.lng,
    super.key,
    this.accuracyM,
  });

  final double lat;
  final double lng;
  final double? accuracyM;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ],
          ),
          if (accuracyM != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.crosshair,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.sos_coordinates_precision(accuracyM!.round()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
