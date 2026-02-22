import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';

class EventFormDateTimeSection extends StatelessWidget {
  const EventFormDateTimeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(title: EventStrings.dateAndTime),
        const SizedBox(height: 12),
        FormBuilderDateRangePicker(
          name: EventFormFields.dateRange,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          decoration: const InputDecoration(
            labelText: EventStrings.dateRange,
            prefixIcon: Icon(Icons.date_range_outlined),
            border: OutlineInputBorder(),
          ),
          validator: FormBuilderValidators.required(
            errorText: EventStrings.dateRangeRequired,
          ),
        ),
        const SizedBox(height: 16),
        AppDatePicker(
          fieldName: EventFormFields.meetingTime,
          labelText: EventStrings.meetingTime,
          inputType: InputType.time,
          prefixIcon: const Icon(Icons.access_time_outlined),
        ),
      ],
    );
  }
}
