import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
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
                      child: _AddressText(
                        meetingPoint: meetingPoint,
                        destination: destination,
                        routePoints: routePoints,
                        hasRoute: hasRoute,
                      ),
                    ),
                    if (onViewMap != null && hasRoute) ...[
                      const SizedBox(width: 12),
                      _ViewMapPill(onTap: onViewMap!),
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

class _AddressText extends StatelessWidget {
  const _AddressText({
    required this.meetingPoint,
    required this.destination,
    required this.routePoints,
    required this.hasRoute,
  });

  final String meetingPoint;
  final String? destination;
  final List<AddressLocation> routePoints;
  final bool hasRoute;

  @override
  Widget build(BuildContext context) {
    // Custom route: show all waypoint labels from routeGeoJson
    if (hasRoute && routePoints.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < routePoints.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _RoutePointText(
              color: i == 0 ? AppColors.success : AppColors.primary,
              label: routePoints[i].label ?? (i == 0 ? meetingPoint : destination ?? ''),
            ),
          ],
        ],
      );
    }

    // Simple route: show meetingPoint text only
    return Text(
      meetingPoint,
      style: const TextStyle(
        color: AppColors.textOnDarkSecondary,
        fontSize: 13,
      ),
    );
  }
}

class _RoutePointText extends StatelessWidget {
  const _RoutePointText({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ViewMapPill extends StatelessWidget {
  const _ViewMapPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.darkBgPrimary,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.event_viewMap,
              style: const TextStyle(
                color: AppColors.darkBgPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
