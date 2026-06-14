import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_type/event_type_row.dart';

/// Event type selector matching Pencil frame zbCa0 — "TIPO DE EVENTO" section.
///
/// Layout: 2 rows of 3 pill chips (cornerRadius 20), gap 8.
/// - Row 1: Turismo · Urbana · Off-road
/// - Row 2: Competición · Solidaria · Corta distancia
///
/// Selected: accent fill (#f98c1f), white bold text (w600).
/// Unselected: darkCard fill, darkBorderPrimary border, text-secondary (w500).
class EventFormEventTypeSection extends StatelessWidget {
  const EventFormEventTypeSection({super.key});

  static const _row1 = [
    EventType.onRoad,
    EventType.offRoad,
    EventType.course,
  ];

  static const _row2 = [
    EventType.trackDay,
    EventType.leisure,
    EventType.competition,
  ];

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<EventType>(
      name: EventFormFields.eventType,
      validator: FormBuilderValidators.required(
        errorText: context.l10n.event_eventTypeRequired,
      ),
      builder: (field) {
        final selected = field.value ?? EventType.onRoad;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TIPO DE EVENTO',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
            const SizedBox(height: 10),
            EventTypeRow(
              types: _row1,
              selected: selected,
              onSelect: field.didChange,
            ),
            const SizedBox(height: 8),
            EventTypeRow(
              types: _row2,
              selected: selected,
              onSelect: field.didChange,
            ),
            if (field.hasError) ...[
              AppSpacing.gapXs,
              Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
