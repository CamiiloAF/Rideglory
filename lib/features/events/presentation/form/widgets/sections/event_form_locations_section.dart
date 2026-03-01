import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/map/route_map_preview.dart';

class EventFormLocationsSection extends StatefulWidget {
  const EventFormLocationsSection({super.key});

  @override
  State<EventFormLocationsSection> createState() =>
      _EventFormLocationsSectionState();
}

class _EventFormLocationsSectionState
    extends State<EventFormLocationsSection> {
  String? _meetingPoint;
  String? _destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Meeting point ──────────────────────────────────────
        AppTextField(
          name: EventFormFields.meetingPoint,
          labelText: EventStrings.meetingPoint,
          isRequired: true,
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.required(
            errorText: EventStrings.meetingPointRequired,
          ),
          onChanged: (value) {
            setState(() => _meetingPoint = value);
          },
        ),
        const SizedBox(height: 16),

        // ── Destination ────────────────────────────────────────
        AppTextField(
          name: EventFormFields.destination,
          labelText: EventStrings.destination,
          isRequired: true,
          prefixIcon: Icons.flag_outlined,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.required(
            errorText: EventStrings.destinationRequired,
          ),
          onChanged: (value) {
            setState(() => _destination = value);
          },
        ),

        // ── Map preview ────────────────────────────────────────
        RouteMapPreview(
          meetingPoint: _meetingPoint,
          destination: _destination,
        ),
      ],
    );
  }
}
