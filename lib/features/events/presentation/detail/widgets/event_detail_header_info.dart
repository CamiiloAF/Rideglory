import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_difficulty_flames.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_organizer_row.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventDetailHeaderInfo extends StatelessWidget {
  const EventDetailHeaderInfo({super.key, required this.event});

  final EventModel event;

  String _badgeLabel(BuildContext context) {
    switch (event.state) {
      case EventState.scheduled:
        return context.l10n.event_comingSoonPill;
      case EventState.inProgress:
        return context.l10n.event_eventLiveNow;
      case EventState.cancelled:
        return event.state.label.toUpperCase();
      case EventState.finished:
        return context.l10n.event_eventFinished.toUpperCase();
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
            color: context.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _badgeLabel(context),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppSpacing.gapMd,
        Text(
          event.name,
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        AppSpacing.gapSm,
        EventDetailOrganizerRow(
          organizerName: context.l10n.event_organizerPlaceholder,
        ),
        AppSpacing.gapMd,
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
            AppSpacing.hGapMd,
            DetailPill(
              leading: Icon(
                Icons.two_wheeler,
                color: context.colorScheme.primary,
                size: 18,
              ),
              label: event.eventType.label.toUpperCase(),
              variant: DetailPillVariant.primary,
            ),
          ],
        ),
        AppSpacing.gapMd,
        DetailPill(
          leading: Icon(
            Icons.access_time,
            color: context.colorScheme.primary,
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
