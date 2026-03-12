import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_allowed_brands_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_destination_card.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart';

class EventDetailBody extends StatelessWidget {
  const EventDetailBody({super.key, required this.event, this.onViewMap});

  final EventModel event;
  final VoidCallback? onViewMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(EventStrings.aboutTheRide),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          EventDetailDestinationCard(destination: event.destination),
          const SizedBox(height: 24),
          EventDetailMeetingPointSection(
            location: event.meetingPoint,
            onViewMap: onViewMap,
          ),
          const SizedBox(height: 24),
          EventDetailAllowedBrandsSection(event: event),
          if (event.recommendations != null &&
              event.recommendations!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            _RecommendationsCard(text: event.recommendations!),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.text});

  final String text;

  List<String> get _items {
    final lines = text
        .split(RegExp(r'\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return lines.isEmpty ? [text] : lines;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                EventStrings.creatorRecommendations,
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line.replaceFirst(RegExp(r'^[\-\*•]\s*'), ''),
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
