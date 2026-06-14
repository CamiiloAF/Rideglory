import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventTypeChip extends StatelessWidget {
  final EventType eventType;

  const EventTypeChip({super.key, required this.eventType});

  Color _getColor(BuildContext context) {
    return switch (eventType) {
      EventType.onRoad => context.appColors.eventTourism,
      EventType.offRoad => context.appColors.eventOffRoad,
      EventType.course => context.appColors.eventUrban,
      EventType.trackDay => context.appColors.eventSolidarity,
      EventType.leisure => context.appColors.eventShortDistance,
      EventType.competition => context.appColors.eventCompetition,
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
