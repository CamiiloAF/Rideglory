import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';

/// Step 3: Route — meeting point, destination, and optional waypoints.
// NOTE: IndexedStack keeps MapboxMap + QuillEditor alive simultaneously.
class EventFormStep3 extends StatelessWidget {
  const EventFormStep3({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: EventFormLocationsSection(),
        ),
        EventStepNavBar(),
      ],
    );
  }
}
