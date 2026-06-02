import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_switch_tile.dart';

class EventFormDateTimeSection extends StatefulWidget {
  const EventFormDateTimeSection({super.key});

  @override
  State<EventFormDateTimeSection> createState() =>
      _EventFormDateTimeSectionState();
}

class _EventFormDateTimeSectionState extends State<EventFormDateTimeSection> {
  bool _isMultiDay = false;
  bool _didLoadInitialValue = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialValue) {
      return;
    }

    final formValue = FormBuilder.of(context)?.instantValue;
    _isMultiDay = formValue?[EventFormFields.isMultiDay] == true;
    _didLoadInitialValue = true;
  }

  @override
  Widget build(BuildContext context) {
    final firstDate = DateTime.now();
    final lastDate = firstDate.add(Duration(days: 365 + (365 / 2).round()));
    final isMultiDayFromForm =
        FormBuilder.of(context)?.instantValue[EventFormFields.isMultiDay] ==
        true;
    final isMultiDay = isMultiDayFromForm || _isMultiDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSwitchTile(
          name: EventFormFields.isMultiDay,
          title: context.l10n.event_isMultiDay,
          onChanged: (value) {
            setState(() {
              _isMultiDay = value;

              final formState = FormBuilder.of(context);
              formState?.fields[EventFormFields.dateRange]?.didChange(null);
            });
          },
        ),
        AppSpacing.gapLg,
        if (isMultiDay)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFieldLabel(
                labelText: context.l10n.event_dateRange,
                isRequired: true,
              ),
              FormBuilderDateRangePicker(
                name: EventFormFields.dateRange,
                firstDate: firstDate,
                lastDate: lastDate,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.event_dateRangeRequired,
                  ),
                  (value) {
                    if (value != null &&
                        value.start.isAtSameMomentAs(value.end)) {
                      return context.l10n.event_startDateMustBeBeforeEndDate;
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
              errorText: context.l10n.event_startDateRequired,
            ),
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFieldLabel(
                    labelText: context.l10n.event_startDate,
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
        AppSpacing.gapLg,
        AppDatePicker(
          fieldName: EventFormFields.meetingTime,
          labelText: context.l10n.event_meetingTime,
          inputType: InputType.time,
        ),
      ],
    );
  }
}
