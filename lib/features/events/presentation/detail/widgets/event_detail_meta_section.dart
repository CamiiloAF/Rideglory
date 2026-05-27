import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// Difficulty pill + type pill + meeting time row.
/// Matches Pencil "Meta Section".
class EventDetailMetaSection extends StatelessWidget {
  const EventDetailMetaSection({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final difficulty = event.difficulty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pills row
        Row(
          children: [
            // Difficulty pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'X${difficulty.value}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '·',
                    style: TextStyle(
                      color: AppColors.textOnDarkTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    difficulty.shortLabel,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Type pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_outlined,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    event.eventType.label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Meeting time row
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              event.meetingTime.formattedTime,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
