import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_filter.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/widgets/participants_filter_chip.dart';

/// Fila horizontal de chips para filtrar participantes por estado.
class ParticipantsFilterChips extends StatelessWidget {
  const ParticipantsFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ParticipantsFilter selected;
  final ValueChanged<ParticipantsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      ParticipantsFilterChip(
        label: context.l10n.map_filterAll,
        isSelected: selected == ParticipantsFilter.all,
        onTap: () => onSelected(ParticipantsFilter.all),
      ),
      ParticipantsFilterChip(
        label: context.l10n.map_filterActive,
        isSelected: selected == ParticipantsFilter.active,
        dotColor: AppColors.success,
        onTap: () => onSelected(ParticipantsFilter.active),
      ),
      ParticipantsFilterChip(
        label: context.l10n.map_filterStopped,
        isSelected: selected == ParticipantsFilter.stopped,
        dotColor: AppColors.tabInactive,
        onTap: () => onSelected(ParticipantsFilter.stopped),
      ),
      ParticipantsFilterChip(
        label: context.l10n.map_filterSos,
        isSelected: selected == ParticipantsFilter.sos,
        dotColor: AppColors.error,
        onTap: () => onSelected(ParticipantsFilter.sos),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) AppSpacing.hGapSm,
            chips[i],
          ],
        ],
      ),
    );
  }
}
