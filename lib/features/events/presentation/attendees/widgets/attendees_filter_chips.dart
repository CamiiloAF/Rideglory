import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_filter_chip.dart';

/// Filtro de estado del piloto en forma de chips horizontales.
/// Corresponde al nodo `filterChips` (i91mh) del diseño Pencil `IUxas`.
///
/// El valor `null` representa "Todos" (sin filtro). Cada chip de estado agrupa
/// los estados equivalentes (p. ej. Pendientes incluye `readyForEdit`).
class AttendeesFilterChips extends StatelessWidget {
  const AttendeesFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Conjunto de estados activos. Vacío = "Todos".
  final Set<RegistrationStatus> selected;
  final ValueChanged<Set<RegistrationStatus>> onSelected;

  static const _pendingGroup = {
    RegistrationStatus.pending,
    RegistrationStatus.readyForEdit,
  };

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      AttendeesFilterChip(
        label: context.l10n.event_filterAll,
        isSelected: selected.isEmpty,
        onTap: () => onSelected(<RegistrationStatus>{}),
      ),
      AttendeesFilterChip(
        label: context.l10n.event_pending,
        isSelected: _pendingGroup.every(selected.contains),
        onTap: () => onSelected(Set.of(_pendingGroup)),
      ),
      AttendeesFilterChip(
        label: context.l10n.event_approved,
        isSelected:
            selected.length == 1 &&
            selected.contains(RegistrationStatus.approved),
        onTap: () => onSelected({RegistrationStatus.approved}),
      ),
      AttendeesFilterChip(
        label: context.l10n.event_rejected,
        isSelected:
            selected.length == 1 &&
            selected.contains(RegistrationStatus.rejected),
        onTap: () => onSelected({RegistrationStatus.rejected}),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
