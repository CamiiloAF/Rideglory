import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventTypeChip extends StatelessWidget {
  final EventType eventType;

  const EventTypeChip({super.key, required this.eventType});

  Color _getColor() {
    switch (eventType) {
      case EventType.offRoad:
        return AppColors.eventOffRoad;
      case EventType.onRoad:
        return AppColors.eventOnRoad;
      case EventType.exhibition:
        return AppColors.eventExhibition;
      case EventType.charitable:
        return AppColors.eventCharitable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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
