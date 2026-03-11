import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_brand_chip.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_date_time_card.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_description_card.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_difficulty_card.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_route_row.dart';

class EventDetailInfoSection extends StatelessWidget {
  const EventDetailInfoSection({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventRouteRow(event: event),
          const SizedBox(height: 20),
          if (!event.isMultiBrand && event.allowedBrands.isNotEmpty) ...[
            Text(
              EventStrings.allowedBrands.toUpperCase(),
              style: TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.allowedBrands
                  .map((b) => EventBrandChip(label: b))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ] else ...[
            EventBrandChip(label: EventStrings.allBrands),
            const SizedBox(height: 20),
          ],
          EventDifficultyCard(difficulty: event.difficulty),
          const SizedBox(height: 24),
          Text(
            'Detalles del evento',
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          EventDateTimeCard(event: event),
          const SizedBox(height: 12),
          EventDescriptionCard(description: event.description),
        ],
      ),
    );
  }
}
