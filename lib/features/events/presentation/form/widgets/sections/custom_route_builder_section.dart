import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_counter.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_item_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_limit_banner.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_search_field.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoints_empty_hint.dart';

const int _maxWaypoints = 9;

class CustomRouteBuilderSection extends StatelessWidget {
  const CustomRouteBuilderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      buildWhen: (prev, curr) => prev.waypoints != curr.waypoints,
      builder: (context, state) {
        final waypoints = state.waypoints;
        final atLimit = waypoints.length >= _maxWaypoints;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.route_builder_section_title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
                WaypointCounter(count: waypoints.length),
              ],
            ),
            const SizedBox(height: 10),
            // Limit warning
            if (atLimit) ...[
              WaypointLimitBanner(
                message: context.l10n.route_builder_limit_banner,
              ),
              const SizedBox(height: 10),
            ],
            // Search field to add waypoint (disabled at limit)
            if (!atLimit)
              WaypointSearchField(
                onPlaceSelected: (name, location) {
                  final cubit = context.read<EventFormCubit>();
                  final index = cubit.state.waypoints.length;
                  cubit.addWaypoint(name);
                  if (location != null) cubit.setWaypointLocation(index, location);
                },
              ),
            if (!atLimit) const SizedBox(height: 10),
            // Waypoints list
            if (waypoints.isEmpty)
              const WaypointsEmptyHint()
            else
              Column(
                children: waypoints.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WaypointItemCard(
                      key: ValueKey('waypoint_${entry.key}'),
                      index: entry.key,
                      name: entry.value,
                      onDelete: () => context
                          .read<EventFormCubit>()
                          .removeWaypoint(entry.key),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}
