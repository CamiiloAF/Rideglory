import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_date_picker_row.dart';

/// Card de fecha + hora para el modo día único en el wizard de creación.
///
/// Design spec (Pencil AybHb):
/// - Card (cornerRadius 12, bg-card, border)
/// - Fecha row: ícono calendario + label + valor + chevron
/// - Divider 1px
/// - Hora row: ícono reloj + label + valor + chevron
class EventSingleDayCard extends StatelessWidget {
  const EventSingleDayCard({
    super.key,
    required this.onPickDate,
    required this.onPickTime,
  });

  final void Function(FormFieldState<DateTimeRange>) onPickDate;
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
      child: Column(
        children: [
          FormBuilderField<DateTimeRange>(
            name: EventFormFields.dateRange,
            validator: FormBuilderValidators.required(
              errorText: context.l10n.event_startDateRequired,
            ),
            builder: (field) {
              final date = field.value?.start;
              final dateText = date != null
                  ? DateFormat('EEE, dd MMM yyyy', 'es').format(date)
                  : context.l10n.event_form_datePlaceholder;
              return EventDatePickerRow(
                icon: Icons.calendar_today_outlined,
                labelText: context.l10n.event_form_dateLabel,
                valueText: dateText,
                hasValue: date != null,
                errorText: field.errorText,
                onTap: () => onPickDate(field),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
          FormBuilderField<DateTime>(
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
                onTap: () => onPickTime(field),
              );
            },
          ),
        ],
      ),
    );
  }
}
