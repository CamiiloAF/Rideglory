import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFormLocationsSection extends StatelessWidget {
  const EventFormLocationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(title: EventStrings.locations),
        const SizedBox(height: 12),
        AppTextField(
          name: EventFormFields.meetingPoint,
          labelText: EventStrings.meetingPoint,
          isRequired: true,
          prefixIcon: Icons.flag_outlined,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.required(
            errorText: EventStrings.meetingPointRequired,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          name: EventFormFields.destination,
          labelText: EventStrings.destination,
          isRequired: true,
          prefixIcon: Icons.location_on_outlined,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.required(
            errorText: EventStrings.destinationRequired,
          ),
        ),
      ],
    );
  }
}
