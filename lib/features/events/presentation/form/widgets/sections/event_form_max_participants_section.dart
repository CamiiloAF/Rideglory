import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/max_participants/max_participants_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/max_participants/max_participants_header.dart';

/// Section for the optional "Máximo de Participantes" field.
///
/// Matches Pencil frame zbCa0 — "MÁXIMO DE PARTICIPANTES" section:
/// - Section header with "Opcional" badge
/// - Card with label (left) + stepper (right): minus / count / plus
/// - Hint row with users icon
///
/// Field value is `null` when not set (no limit).
/// First "+" tap activates the field at min value (5).
/// Tapping "–" when at min returns to null.
class EventFormMaxParticipantsSection extends StatelessWidget {
  const EventFormMaxParticipantsSection({super.key});

  static const int _min = 5;
  static const int _max = 500;
  static const int _step = 5;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<int?>(
      name: EventFormFields.maxParticipants,
      builder: (field) {
        final count = field.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MaxParticipantsHeader(),
            const SizedBox(height: 10),
            MaxParticipantsCard(
              count: count,
              onDecrement: () {
                if (count == null || count <= _min) {
                  field.didChange(null);
                } else {
                  field.didChange(count - _step);
                }
              },
              onIncrement: () {
                if (count == null) {
                  field.didChange(_min);
                } else if (count < _max) {
                  field.didChange(count + _step);
                }
              },
              onManualChange: field.didChange,
            ),
          ],
        );
      },
    );
  }
}
