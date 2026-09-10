import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../event_external_actions.dart';

/// Sección DESTINO del detalle: mapa mini (placeholder, sin mapa
/// interactivo en v2), nombre y botón para abrir en la app de mapas.
class EventDetailDestinationSection extends StatelessWidget {
  const EventDetailDestinationSection({
    required this.destinationName,
    required this.lat,
    required this.lng,
    super.key,
  });

  final String destinationName;
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.events_detail_destination_label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: colors.borderStrong),
          ),
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.mapPin,
            size: 28,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          destinationName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: context.l10n.events_detail_open_maps,
          icon: LucideIcons.navigation,
          onPressed: () => openMapsForDestination(
            lat: lat,
            lng: lng,
            label: destinationName,
          ),
        ),
      ],
    );
  }
}
