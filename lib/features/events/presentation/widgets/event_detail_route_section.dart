import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Sección RUTA del detalle: el texto libre del organizador.
class EventDetailRouteSection extends StatelessWidget {
  const EventDetailRouteSection({required this.routeText, super.key});

  final String routeText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.events_detail_route_label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          routeText,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
