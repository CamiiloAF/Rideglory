import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';

class EventFormDateTimeSection extends StatefulWidget {
  const EventFormDateTimeSection({super.key});

  @override
  State<EventFormDateTimeSection> createState() =>
      _EventFormDateTimeSectionState();
}

class _EventFormDateTimeSectionState extends State<EventFormDateTimeSection> {
  bool _isMultiDay = false;

  @override
  Widget build(BuildContext context) {
    final firstDate = DateTime.now();
    final lastDate = firstDate.add(Duration(days: 365 + (365 / 2).round()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(title: EventStrings.dateAndTime),
        const SizedBox(height: 12),
        FormBuilderSwitch(
          name: EventFormFields.isMultiDay,
          title: const Text(EventStrings.isMultiDay),

          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onChanged: (value) {
            setState(() {
              _isMultiDay = value ?? false;

              final formState = FormBuilder.of(context);
              formState?.fields[EventFormFields.dateRange]?.didChange(null);
            });
          },
        ),
        const SizedBox(height: 16),
        if (_isMultiDay)
          FormBuilderDateRangePicker(
            name: EventFormFields.dateRange,
            firstDate: firstDate,
            lastDate: lastDate,

            decoration: const InputDecoration(
              labelText: EventStrings.dateRange,
              prefixIcon: Icon(Icons.date_range_outlined),
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: EventStrings.dateRangeRequired,
              ),
              (value) {
                if (value != null && value.start.isAtSameMomentAs(value.end)) {
                  return EventStrings.startDateMustBeBeforeEndDate;
                }
                return null;
              },
            ]),
          )
        else
          FormBuilderField<DateTimeRange>(
            name: EventFormFields.dateRange,
            validator: FormBuilderValidators.required(
              errorText: EventStrings.startDateRequired,
            ),
            builder: (field) {
              return FormBuilderDateTimePicker(
                name: '_singleDate_temp',
                inputType: InputType.date,
                firstDate: firstDate,
                lastDate: lastDate,
                initialValue: field.value?.start,
                decoration: const InputDecoration(
                  labelText: EventStrings.startDate,
                  prefixIcon: Icon(Icons.event_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (date) {
                  if (date != null) {
                    field.didChange(DateTimeRange(start: date, end: date));
                  }
                },
              );
            },
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
