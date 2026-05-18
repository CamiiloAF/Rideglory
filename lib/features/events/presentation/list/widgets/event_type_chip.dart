import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventTypeChip extends StatelessWidget {
  final EventType eventType;

  const EventTypeChip({super.key, required this.eventType});

  Color _getColor(BuildContext context) {
    return switch (eventType) {
      EventType.tourism => context.appColors.eventTourism,
      EventType.urban => context.appColors.eventUrban,
      EventType.offRoad => context.appColors.eventOffRoad,
      EventType.competition => context.appColors.eventCompetition,
      EventType.solidarity => context.appColors.eventSolidarity,
      EventType.shortDistance => context.appColors.eventShortDistance,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        eventType.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
