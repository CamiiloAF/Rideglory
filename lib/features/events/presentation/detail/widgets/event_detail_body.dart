import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_allowed_brands_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_destination_card.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_info.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_section_title.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
          EventDetailHeaderInfo(event: event),
          AppSpacing.gapXxl,
          EventDetailSectionTitle(title: context.l10n.event_aboutTheRide),
          AppSpacing.gapSm,
          RichTextViewer(content: event.description),
          AppSpacing.gapXl,
          EventDetailDestinationCard(destination: event.destination),
          AppSpacing.gapXxl,
          EventDetailMeetingPointSection(
            location: event.meetingPoint,
            onViewMap: onViewMap,
          ),
          AppSpacing.gapXxl,
          EventDetailAllowedBrandsSection(event: event),
        ],
      ),
    );
  }
}
