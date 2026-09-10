import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/event_route_change.dart';

/// Avisos de cambio de ruta visibles en el detalle (organizador e
/// inscritos). No se muestra nada si no hay ninguno.
class EventRouteChangesSection extends StatelessWidget {
  const EventRouteChangesSection({required this.changes, super.key});

  final List<EventRouteChange> changes;

  @override
  Widget build(BuildContext context) {
    if (changes.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.events_detail_route_changes_title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        for (final change in changes) ...[
          AppBanner(
            icon: LucideIcons.milestone,
            title: context.l10n.events_detail_change_route_cta,
            body: change.message,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
