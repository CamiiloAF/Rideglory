import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../domain/event.dart';
import '../../domain/event_route_change.dart';
import 'event_detail_data_rows.dart';
import 'event_detail_destination_section.dart';
import 'event_detail_hero.dart';
import 'event_detail_organizer_row.dart';
import 'event_detail_route_section.dart';
import 'event_detail_section_divider.dart';
import 'event_route_changes_section.dart';
import 'event_start_overdue_banner.dart';

/// Cuerpo scrolleable del detalle: hero + toda la información. El footer
/// de acciones vive fuera de este widget (se pinta encima, fijo).
class EventDetailBody extends StatelessWidget {
  const EventDetailBody({
    required this.event,
    required this.routeChanges,
    required this.showSpotsUnderOrganizer,
    required this.spotsLabel,
    required this.meetingPointLabel,
    required this.bottomPadding,
    super.key,
  });

  final Event event;
  final List<EventRouteChange> routeChanges;
  final bool showSpotsUnderOrganizer;
  final String spotsLabel;
  final String meetingPointLabel;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventDetailHero(
            difficulty: event.difficulty,
            imageUrl: event.imageUrl,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.isOwnedByMe && event.isOverdueToStart)
                  EventStartOverdueBanner(startAt: event.startAt),
                Text(
                  event.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 16),
                EventDetailDataRows(
                  startAt: event.startAt,
                  meetingPointLabel: meetingPointLabel,
                ),
                const SizedBox(height: 16),
                const EventDetailSectionDivider(),
                const SizedBox(height: 16),
                if (event.destinationLat != null &&
                    event.destinationLng != null) ...[
                  EventDetailDestinationSection(
                    destinationName: event.destinationName ?? '',
                    lat: event.destinationLat!,
                    lng: event.destinationLng!,
                  ),
                  const SizedBox(height: 16),
                  const EventDetailSectionDivider(),
                  const SizedBox(height: 16),
                ],
                if (event.routeText != null &&
                    event.routeText!.trim().isNotEmpty) ...[
                  EventDetailRouteSection(routeText: event.routeText!),
                  const SizedBox(height: 16),
                  const EventDetailSectionDivider(),
                  const SizedBox(height: 16),
                ],
                EventDetailOrganizerRow(
                  organizerName: event.ownerName,
                  spotsLabel: showSpotsUnderOrganizer ? spotsLabel : null,
                ),
                if (routeChanges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const EventDetailSectionDivider(),
                  const SizedBox(height: 16),
                  EventRouteChangesSection(changes: routeChanges),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
