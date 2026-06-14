import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_type/event_type_chip.dart';

class EventTypeRow extends StatelessWidget {
  const EventTypeRow({
    super.key,
    required this.types,
    required this.selected,
    required this.onSelect,
  });

  final List<EventType> types;
  final EventType selected;
  final void Function(EventType) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: EventTypeChip(
              type: types[i],
              isSelected: selected == types[i],
              onTap: () => onSelect(types[i]),
            ),
          ),
        ],
      ],
    );
  }
}
