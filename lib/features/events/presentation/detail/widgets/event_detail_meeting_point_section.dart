import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/sections/event_detail_address_text.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/sections/event_detail_view_map_pill.dart';
import 'package:rideglory/shared/models/address_location.dart';

/// Route section in the event detail.
///
/// Shows a live [RouteMapPreview] when [routePoints] are available,
/// otherwise falls back to a placeholder icon.
/// The "Ver mapa" pill opens a full-screen read-only map via [onViewMap].
class EventDetailMeetingPointSection extends StatelessWidget {
  const EventDetailMeetingPointSection({
    super.key,
    required this.meetingPoint,
    this.destination,
    this.routePoints = const [],
    this.onViewMap,
  });

  final String meetingPoint;
  final String? destination;
  final List<AddressLocation> routePoints;
  final VoidCallback? onViewMap;

  @override
  Widget build(BuildContext context) {
    final hasRoute = routePoints.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_meetingPointLabel,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Map area ─────────────────────────────────────────────
              if (hasRoute)
                RouteMapPreview(
                  waypointCoords: routePoints,
                  inCard: true,
                )
              else
                Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.darkTertiary,
                  child: const Center(
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ),

              // ── Address row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: EventDetailAddressText(
                        meetingPoint: meetingPoint,
                        destination: destination,
                        routePoints: routePoints,
                        hasRoute: hasRoute,
                      ),
                    ),
                    if (onViewMap != null && hasRoute) ...[
                      const SizedBox(width: 12),
                      EventDetailViewMapPill(onTap: onViewMap!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
