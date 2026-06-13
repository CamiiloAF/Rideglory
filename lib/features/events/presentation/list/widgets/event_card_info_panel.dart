import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventCardInfoPanel extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback? onStartEvent;
  final bool isOwner;
  final bool isRegistered;
  final bool showJoinButton;

  const EventCardInfoPanel({
    super.key,
    required this.event,
    required this.onTap,
    this.onStartEvent,
    this.isOwner = false,
    this.isRegistered = false,
    this.showJoinButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: context.titleLarge?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.hGapSm,
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.local_fire_department,
                      size: 17,
                      color: i < event.difficulty.value
                          ? context.colorScheme.primary
                          : context.colorScheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
              AppSpacing.hGapXs,
              Text(
                '${event.startDate.formattedDate} • ${event.meetingTime.formattedTime}',
                style: context.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
              AppSpacing.hGapXs,
              Expanded(
                child: Text(
                  event.meetingPoint,
                  style: context.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          if (showJoinButton)
            AppButton(
              label: context.l10n.event_joinEvent,
              onPressed: onTap,
            )
          else if (isOwner && event.state == EventState.scheduled)
            AppButton(
              label: context.l10n.event_startEvent,
              isFullWidth: true,
              onPressed: onStartEvent,
            )
          else if (!isOwner && isRegistered)
            Text(
              context.l10n.event_alreadyRegistered,
              style: context.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              context.l10n.event_eventCardMyEvent,
              style: context.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
