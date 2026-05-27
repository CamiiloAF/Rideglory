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
      children: types
          .map(
            (type) => Padding(
              padding: EdgeInsets.only(right: type != types.last ? 8 : 0),
              child: EventTypeChip(
                type: type,
                isSelected: selected == type,
                onTap: () => onSelect(type),
              ),
            ),
          )
          .toList(),
    );
  }
}
