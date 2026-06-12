import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_route_type_selector.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/locations/custom_route_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/locations/simple_route_card.dart';

/// Route section with dual behavior:
/// - Simple route: inline Route Card with meeting point + destination
///   autocomplete fields + map preview.
/// - Custom route: "Crear ruta personalizada" button → [EventRouteConfigScreen].
///   After configuration, shows map with numbered pins + polyline + waypoints list.
class EventFormLocationsSection extends StatelessWidget {
  const EventFormLocationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventFormCubit, EventFormState>(
      buildWhen: (prev, curr) =>
          prev.routeType != curr.routeType ||
          prev.meetingPointName != curr.meetingPointName ||
          prev.destinationName != curr.destinationName ||
          prev.meetingPointLocation != curr.meetingPointLocation ||
          prev.destinationLocation != curr.destinationLocation ||
          prev.waypoints != curr.waypoints ||
          prev.waypointLocations != curr.waypointLocations,
      builder: (context, state) {
        final isCustom = state.routeType == RouteType.custom;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_route,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
            const SizedBox(height: 10),
            EventRouteTypeSelector(
              onChanged: (type) {
                if (type == null) return;
                final cubit = context.read<EventFormCubit>();
                cubit.setRouteType(type);
                if (type == RouteType.simple) cubit.clearWaypoints();
              },
            ),
            const SizedBox(height: 12),
            if (isCustom)
              CustomRouteSection(state: state)
            else
              SimpleRouteCard(state: state),
          ],
        );
      },
    );
  }
}
