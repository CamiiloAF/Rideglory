import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Fila del organizador. [spotsLabel] solo se muestra en la vista de
/// organizador (Pencil: `EV2 — Organizador`), como subtítulo bajo el
/// nombre.
class EventDetailOrganizerRow extends StatelessWidget {
  const EventDetailOrganizerRow({
    required this.organizerName,
    this.spotsLabel,
    super.key,
  });

  final String organizerName;
  final String? spotsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.block,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(LucideIcons.user, size: 18, color: colors.onBlock),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.events_detail_organizer_prefix(organizerName),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            if (spotsLabel != null)
              Text(
                spotsLabel!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
