import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/sections/event_detail_route_point_text.dart';
import 'package:rideglory/shared/models/address_location.dart';

class EventDetailAddressText extends StatelessWidget {
  const EventDetailAddressText({
    super.key,
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
            EventDetailRoutePointText(
              color: i == 0 ? AppColors.success : AppColors.primary,
              label:
                  routePoints[i].label ??
                  (i == 0 ? meetingPoint : destination ?? ''),
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
