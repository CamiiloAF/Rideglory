import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventRouteRow extends StatelessWidget {
  const EventRouteRow({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.map_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trayecto',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                '${event.meetingPoint} → ${event.destination}',
                style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
