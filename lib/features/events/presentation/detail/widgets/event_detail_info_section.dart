import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_info_row.dart';

class EventDetailInfoSection extends StatelessWidget {
  final EventModel event;
  const EventDetailInfoSection({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          EventInfoRow(
            icon: Icons.access_time_outlined,
            label: EventStrings.timeLabel,
            value: DateFormat('HH:mm').format(event.meetingTime),
          ),
          const SizedBox(height: 12),
          EventInfoRow(
            icon: Icons.flag_outlined,
            label: EventStrings.meetingPointLabel,
            value: event.meetingPoint,
          ),
          const SizedBox(height: 12),
          EventInfoRow(
            icon: Icons.location_on_outlined,
            label: EventStrings.destinationLabel,
            value: event.destination,
          ),
        ],
      ),
    );
  }
}
