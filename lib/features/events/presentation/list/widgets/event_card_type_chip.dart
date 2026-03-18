import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventCardTypeChip extends StatelessWidget {
  final EventType eventType;

  const EventCardTypeChip({super.key, required this.eventType});

  static Color _colorFor(BuildContext context, EventType type) {
    switch (type) {
      case EventType.offRoad:
        return context.appColors.eventOffRoad;
      case EventType.onRoad:
        return context.appColors.eventOnRoad;
      case EventType.exhibition:
        return context.appColors.eventExhibition;
      case EventType.charitable:
        return context.appColors.eventCharitable;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _colorFor(context, eventType),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        eventType.label.toUpperCase(),
        style: context.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
