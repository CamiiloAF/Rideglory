import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/events_list_state.dart';
import 'internal/events_segment_button.dart';

/// Segmentos "Próximas" / "Mías" de EV1.
///
/// Pencil: j4t1js (dentro de EV1 — Lista)
class EventsSegmentedControl extends StatelessWidget {
  const EventsSegmentedControl({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final EventsSegment selected;
  final ValueChanged<EventsSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: EventsSegmentButton(
              label: context.l10n.events_segment_upcoming,
              isSelected: selected == EventsSegment.upcoming,
              onTap: () => onSelected(EventsSegment.upcoming),
            ),
          ),
          Expanded(
            child: EventsSegmentButton(
              label: context.l10n.events_segment_mine,
              isSelected: selected == EventsSegment.mine,
              onTap: () => onSelected(EventsSegment.mine),
            ),
          ),
        ],
      ),
    );
  }
}
