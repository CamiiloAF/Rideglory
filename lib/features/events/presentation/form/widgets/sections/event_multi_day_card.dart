import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_date_picker_row.dart';

/// Card de fecha inicio + fecha fin + hora para el modo varios días.
///
/// Al tocar "Fecha de inicio" o "Fecha de fin" se abre el date picker nativo,
/// actualizando el campo [EventFormFields.dateRange] con el valor correspondiente.
class EventMultiDayCard extends StatelessWidget {
  const EventMultiDayCard({
    super.key,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onPickTime,
  });

  final void Function(FormFieldState<DateTimeRange>) onPickStartDate;
  final void Function(FormFieldState<DateTimeRange>) onPickEndDate;
  final void Function(FormFieldState<DateTime>) onPickTime;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: FormBuilderField<DateTimeRange>(
        name: EventFormFields.dateRange,
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(
            errorText: context.l10n.event_dateRangeRequired,
          ),
          (value) {
            if (value != null &&
                !value.end.isAfter(value.start) &&
                !value.start.isAtSameMomentAs(value.end)) {
              return null;
            }
            if (value != null && value.start.isAtSameMomentAs(value.end)) {
              return context.l10n.event_startDateMustBeBeforeEndDate;
            }
            return null;
          },
        ]),
        builder: (field) {
          final range = field.value;
          final startText = range != null
              ? DateFormat('EEE, dd MMM yyyy', 'es').format(range.start)
              : context.l10n.event_form_datePlaceholder;
          final endText = range?.end != null && range!.end != range.start
              ? DateFormat('EEE, dd MMM yyyy', 'es').format(range.end)
              : context.l10n.event_form_datePlaceholder;

          return Column(
            children: [
              EventDatePickerRow(
                icon: Icons.calendar_today_outlined,
                labelText: context.l10n.event_startDate,
                valueText: startText,
                hasValue: range != null,
                errorText: field.errorText,
                onTap: () => onPickStartDate(field),
              ),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              EventDatePickerRow(
                icon: Icons.event_outlined,
                labelText: context.l10n.event_endDate,
                valueText: endText,
                hasValue: range?.end != null && range!.end != range.start,
                onTap: () => onPickEndDate(field),
              ),
              const Divider(height: 1, color: AppColors.darkBorderPrimary),
              FormBuilderField<DateTime>(
                name: EventFormFields.meetingTime,
                initialValue: DateTime(now.year, now.month, now.day, 7, 0),
                builder: (timeField) {
                  final time = timeField.value;
                  final timeText = time != null
                      ? DateFormat('hh:mm a').format(time)
                      : context.l10n.event_form_timePlaceholder;
                  return EventDatePickerRow(
                    icon: Icons.access_time_rounded,
                    labelText: context.l10n.event_form_timeLabel,
                    valueText: timeText,
                    hasValue: time != null,
                    onTap: () => onPickTime(timeField),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
