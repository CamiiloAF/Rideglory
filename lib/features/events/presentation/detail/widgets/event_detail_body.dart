import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_allowed_brands_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_destination_card.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart';
import 'package:rideglory/shared/widgets/rich_text_viewer.dart';

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
          RichTextViewer(content: event.description),
          const SizedBox(height: 20),
          EventDetailDestinationCard(destination: event.destination),
          const SizedBox(height: 24),
          EventDetailMeetingPointSection(
            location: event.meetingPoint,
            onViewMap: onViewMap,
          ),
          const SizedBox(height: 24),
          EventDetailAllowedBrandsSection(event: event),
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
