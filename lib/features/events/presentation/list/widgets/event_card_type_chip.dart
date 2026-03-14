import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventCardTypeChip extends StatelessWidget {
  final EventType eventType;

  const EventCardTypeChip({super.key, required this.eventType});

  static Color _colorFor(EventType type) {
    switch (type) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _colorFor(eventType),
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
