import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class EventFormDateTimeSection extends StatefulWidget {
  const EventFormDateTimeSection({super.key});

  @override
  State<EventFormDateTimeSection> createState() =>
      _EventFormDateTimeSectionState();
}

class _EventFormDateTimeSectionState extends State<EventFormDateTimeSection> {
  bool _isMultiDay = false;

  @override
  void initState() {
    //TODO FIX EDIT MULTIDATE
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final firstDate = DateTime.now();
    final lastDate = firstDate.add(Duration(days: 365 + (365 / 2).round()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFieldLabel(
                labelText: EventStrings.dateRange,
                isRequired: true,
              ),
              FormBuilderDateRangePicker(
                name: EventFormFields.dateRange,
                firstDate: firstDate,
                lastDate: lastDate,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: EventStrings.dateRangeRequired,
                  ),
                  (value) {
                    if (value != null &&
                        value.start.isAtSameMomentAs(value.end)) {
                      return EventStrings.startDateMustBeBeforeEndDate;
                    }
                    return null;
                  },
                ]),
              ),
            ],
          )
        else
          FormBuilderField<DateTimeRange>(
            name: EventFormFields.dateRange,
            validator: FormBuilderValidators.required(
              errorText: EventStrings.startDateRequired,
            ),
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFieldLabel(
                    labelText: EventStrings.startDate,
                    isRequired: true,
                  ),
                  FormBuilderDateTimePicker(
                    name: '_singleDate_temp',
                    inputType: InputType.date,
                    firstDate: field.value?.start ?? firstDate,
                    lastDate: lastDate,
                    initialValue: field.value?.start,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (date) {
                      if (date != null) {
                        field.didChange(DateTimeRange(start: date, end: date));
                      }
                    },
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        AppDatePicker(
          fieldName: EventFormFields.meetingTime,
          labelText: EventStrings.meetingTime,
          inputType: InputType.time,
        ),
      ],
    );
  }
}
