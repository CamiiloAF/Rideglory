import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_single_day_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_date_picker_row.dart';
import 'package:rideglory/shared/widgets/form/app_switch_tile.dart';

/// Sección de fecha y hora del wizard de creación de eventos.
///
/// Design spec (Pencil AybHb):
/// - AppSwitchTile "Varios días"
/// - Día único: EventSingleDayCard
/// - Multi-día: range picker + hora card estándar
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
    if (_didLoadInitialValue) return;
    final formValue = FormBuilder.of(context)?.instantValue;
    _isMultiDay = formValue?[EventFormFields.isMultiDay] == true;
    _didLoadInitialValue = true;
  }

  Future<void> _pickDate(FormFieldState<DateTimeRange> field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: field.value?.start ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 548)),
    );
    if (picked != null && mounted) {
      field.didChange(DateTimeRange(start: picked, end: picked));
    }
  }

  Future<void> _pickTime(FormFieldState<DateTime> field) async {
    final initial = field.value != null
        ? TimeOfDay.fromDateTime(field.value!)
        : const TimeOfDay(hour: 7, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      final now = DateTime.now();
      field.didChange(
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastDate = now.add(const Duration(days: 548));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSwitchTile(
          name: EventFormFields.isMultiDay,
          title: context.l10n.event_isMultiDay,
          onChanged: (value) {
            setState(() {
              _isMultiDay = value;
              FormBuilder.of(context)
                  ?.fields[EventFormFields.dateRange]
                  ?.didChange(null);
            });
          },
        ),
        AppSpacing.gapLg,
        if (_isMultiDay) ...[
          FormBuilderDateRangePicker(
            name: EventFormFields.dateRange,
            firstDate: now,
            lastDate: lastDate,
            decoration: InputDecoration(
              hintText: context.l10n.event_filterDateHint,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: context.l10n.event_dateRangeRequired,
              ),
              (value) {
                if (value != null && value.start.isAtSameMomentAs(value.end)) {
                  return context.l10n.event_startDateMustBeBeforeEndDate;
                }
                return null;
              },
            ]),
          ),
          AppSpacing.gapLg,
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: FormBuilderField<DateTime>(
              name: EventFormFields.meetingTime,
              initialValue: DateTime(now.year, now.month, now.day, 7, 0),
              builder: (field) {
                final time = field.value;
                final timeText = time != null
                    ? DateFormat('hh:mm a').format(time)
                    : context.l10n.event_form_timePlaceholder;
                return EventDatePickerRow(
                  icon: Icons.access_time_rounded,
                  labelText: context.l10n.event_form_timeLabel,
                  valueText: timeText,
                  hasValue: time != null,
                  onTap: () => _pickTime(field),
                );
              },
            ),
          ),
        ] else
          EventSingleDayCard(
            onPickDate: _pickDate,
            onPickTime: _pickTime,
          ),
      ],
    );
  }
}
