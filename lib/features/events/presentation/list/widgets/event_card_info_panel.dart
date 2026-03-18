import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventCardInfoPanel extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCardInfoPanel({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMM yyyy', 'es');
    final timeFormatter = DateFormat('hh:mm a', 'es');

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
              SizedBox(width: 10),
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
          SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 6),
              Text(
                '${dateFormatter.format(event.startDate)} • ${timeFormatter.format(event.meetingTime)}',
                style: context.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: context.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.city,
                  style: context.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          AppButton(
            label: context.l10n.event_joinEvent,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
