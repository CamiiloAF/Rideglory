import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/locations/route_point_display_row.dart';
import 'package:rideglory/shared/models/address_location.dart';

class RoutePointsCard extends StatelessWidget {
  const RoutePointsCard({super.key, required this.state, this.onEmptyTap});

  final EventFormState state;
  final VoidCallback? onEmptyTap;

  @override
  Widget build(BuildContext context) {
    final waypoints = state.waypoints;

    if (waypoints.isEmpty) {
      return GestureDetector(
        onTap: onEmptyTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          child: Center(
            child: Text(
              context.l10n.route_empty_hint,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 13,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
          ),
        ),
      );
    }

    final hasEnd = waypoints.length >= 2;
    final intermediates =
        waypoints.length > 2 ? waypoints.sublist(1, waypoints.length - 1) : <String>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        children: [
          RoutePointDisplayRow(
            typeLabel: context.l10n.route_point_start,
            name: waypoints.first,
            iconBg: const Color(0xFF1B2B1B),
            icon: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
          ),
          for (final wp in intermediates) ...[
            const Divider(height: 1, color: AppColors.darkBorderPrimary),
            RoutePointDisplayRow(
              typeLabel: context.l10n.route_point_waypoint,
              name: wp,
              iconBg: const Color(0xFF2D2117),
              icon: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
          if (hasEnd) ...[
            const Divider(height: 1, color: AppColors.darkBorderPrimary),
            RoutePointDisplayRow(
              typeLabel: context.l10n.route_point_end,
              name: waypoints.last,
              iconBg: const Color(0xFF2D1A1A),
              icon: const Icon(
                Icons.flag,
                color: Color(0xFFEF4444),
                size: 16,
              ),
            ),
          ],
          RouteMapPreview(
            inCard: true,
            waypointCoords: state.waypointLocations
                .whereType<AddressLocation>()
                .toList(),
          ),
        ],
      ),
    );
  }
}
