import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_chip.dart';

class EventDetailHeader extends StatelessWidget {
  final EventModel event;

  const EventDetailHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                event.city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateRange(event),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EventDetailChip(
                label: event.eventType.label,
                color: colorScheme.primary,
              ),
              EventDetailChip(
                label: '🌶' * event.difficulty.value,
                color: Colors.red,
              ),
              EventDetailChip(
                label: event.isFree
                    ? EventStrings.free
                    : '\$${event.price!.toStringAsFixed(0)}',
                color: event.isFree ? Colors.green : Colors.orange,
              ),
              EventDetailChip(
                label: event.isMultiBrand
                    ? EventStrings.openToAllBrands
                    : event.allowedBrands.join(', '),
                color: colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateRange(EventModel event) {
    final formatter = DateFormat('d MMM yyyy', 'es');
    final start = formatter.format(event.startDate);
    if (event.endDate != null) {
      return '$start – ${formatter.format(event.endDate!)}';
    }
    return start;
  }
}
