import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/locations/waypoint_preview_row.dart';
import 'package:rideglory/shared/models/address_location.dart';

class CustomRouteSummaryCard extends StatelessWidget {
  const CustomRouteSummaryCard({super.key, required this.state});

  final EventFormState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Waypoints list preview (max 3 shown)
          ...state.waypoints.take(3).toList().asMap().entries.map((entry) {
            return WaypointPreviewRow(
              index: entry.key,
              name: entry.value,
              isLast: entry.key == state.waypoints.length - 1 || entry.key == 2,
            );
          }),
          if (state.waypoints.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                '+${state.waypoints.length - 3} más',
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 12,
                  color: AppColors.textOnDarkTertiary,
                ),
              ),
            ),
          // Map preview
          RouteMapPreview(
            waypointCoords: state.waypointLocations
                .whereType<AddressLocation>()
                .toList(),
            inCard: true,
          ),
        ],
      ),
    );
  }
}
