import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventFormLocationsSection extends StatefulWidget {
  const EventFormLocationsSection({super.key});

  @override
  State<EventFormLocationsSection> createState() =>
      _EventFormLocationsSectionState();
}

class _EventFormLocationsSectionState extends State<EventFormLocationsSection> {
  String? _meetingPoint;
  String? _destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          name: EventFormFields.meetingPoint,
          hintText: context.l10n.event_meetingPoint,
          isRequired: true,
          prefixIcon: Icons.radio_button_unchecked,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.required(
            errorText: context.l10n.event_meetingPointRequired,
          ),
          onChanged: (value) {
            setState(() => _meetingPoint = value);
          },
        ),
        AppSpacing.gapLg,

        AppTextField(
          name: EventFormFields.destination,
          hintText: context.l10n.event_finalDestination,
          isRequired: true,
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.required(
            errorText: context.l10n.event_destinationRequired,
          ),
          onChanged: (value) {
            setState(() => _destination = value);
          },
        ),
        AppSpacing.gapXxl,
        FormSectionTitle(
          title: context.l10n.event_meetingPointPreview.toUpperCase(),
          icon: Icons.map_outlined,
        ),
        RouteMapPreview(
          meetingPoint: _meetingPoint,
          destination: _destination,
          onViewMapTap: () {
            // TODO: open full map or external app
          },
        ),
      ],
    );
  }
}
