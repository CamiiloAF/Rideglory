import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/shared/helpers/map_launcher_helper.dart';
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
  bool _didLoadInitialValues = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialValues) {
      return;
    }

    final formValue = FormBuilder.of(context)?.instantValue;
    _meetingPoint = (formValue?[EventFormFields.meetingPoint] as String?)
        ?.trim();
    _destination = (formValue?[EventFormFields.destination] as String?)?.trim();
    _didLoadInitialValues = true;
  }

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
            setState(() => _meetingPoint = value?.trim());
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
            setState(() => _destination = value?.trim());
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
            final meetingPoint = _meetingPoint?.trim();
            if (meetingPoint == null || meetingPoint.isEmpty) {
              return;
            }

            final destination = _destination?.trim();
            if (destination != null && destination.isNotEmpty) {
              unawaited(
                MapLauncherHelper.openDirections(
                  origin: meetingPoint,
                  destination: destination,
                ),
              );
              return;
            }

            unawaited(MapLauncherHelper.openSearchByAddress(meetingPoint));
          },
        ),
      ],
    );
  }
}
