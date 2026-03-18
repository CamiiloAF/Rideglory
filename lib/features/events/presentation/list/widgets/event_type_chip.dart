import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class EventTypeChip extends StatelessWidget {
  final EventType eventType;

  const EventTypeChip({super.key, required this.eventType});

  Color _getColor(BuildContext context) {
    switch (eventType) {
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
