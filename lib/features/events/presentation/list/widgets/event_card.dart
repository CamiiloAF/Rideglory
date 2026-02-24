import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_chips_row.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_date_and_city.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_header.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card_meeting_time_and_brands.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  static final _dateFormatter = DateFormat('d MMM yyyy', 'es');
  static final _timeFormatter = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventCardHeader(
                eventName: event.name,
                isOwner: isOwner,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
              const SizedBox(height: 8),
              EventCardChipsRow(
                eventType: event.eventType,
                difficulty: event.difficulty,
                isFree: event.isFree,
                price: event.price,
              ),
              const SizedBox(height: 10),
              EventCardDateAndCity(
                formattedDate: _formatDateRange(),
                city: event.city,
              ),
              const SizedBox(height: 6),
              EventCardMeetingTimeAndBrands(
                formattedTime: _timeFormatter.format(event.meetingTime),
                isMultiBrand: event.isMultiBrand,
                allowedBrands: event.allowedBrands,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange() {
    final start = _dateFormatter.format(event.startDate);
    if (event.endDate != null && event.endDate != event.startDate) {
      return '$start – ${_dateFormatter.format(event.endDate!)}';
    }
    return start;
  }
}
