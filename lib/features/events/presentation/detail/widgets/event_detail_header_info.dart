import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_difficulty_flames.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_organizer_row.dart';
import 'package:rideglory/shared/widgets/detail_pill.dart';

class EventDetailHeaderInfo extends StatelessWidget {
  const EventDetailHeaderInfo({super.key, required this.event});

  final EventModel event;

  String get _badgeLabel {
    switch (event.state) {
      case EventState.scheduled:
        return EventStrings.comingSoonPill;
      case EventState.inProgress:
        return EventStrings.eventLiveNow;
      case EventState.cancelled:
        return event.state.label.toUpperCase();
      case EventState.finished:
        return EventStrings.eventFinished.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _badgeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          event.name,
          style: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        const EventDetailOrganizerRow(
          organizerName: EventStrings.organizerPlaceholder,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            DetailPill(
              leading: EventDetailDifficultyFlames(
                level: event.difficulty.value,
              ),
              label: EventDifficulty.fromValue(
                event.difficulty.value,
              ).shortLabel,
              variant: DetailPillVariant.primary,
            ),
            const SizedBox(width: 12),
            DetailPill(
              leading: const Icon(
                Icons.two_wheeler,
                color: AppColors.primary,
                size: 18,
              ),
              label: event.eventType.label.toUpperCase(),
              variant: DetailPillVariant.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailPill(
          leading: const Icon(
            Icons.access_time,
            color: AppColors.primary,
            size: 18,
          ),
          subtitle: 'HORA',
          label: '${DateFormat('HH:mm').format(event.meetingTime)}h',
          variant: DetailPillVariant.primary,
        ),
      ],
    );
  }
}
