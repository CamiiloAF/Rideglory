import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/difficulty/difficulty_card.dart';

/// Difficulty section matching Pencil frame zbCa0 — "DIFICULTAD" section:
/// - Section header "DIFICULTAD"
/// - Card: top row with label (left) + 5 flame icons (right), description below
class EventFormDifficultySection extends StatelessWidget {
  const EventFormDifficultySection({super.key});

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<EventDifficulty>(
      name: EventFormFields.difficulty,
      validator: FormBuilderValidators.required(
        errorText: context.l10n.event_difficultyRequired,
      ),
      builder: (field) {
        final selected = field.value ?? EventDifficulty.one;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_form_difficulty_section_title,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
            const SizedBox(height: 10),
            DifficultyCard(selected: selected, onSelect: field.didChange),
            if (field.hasError) ...[
              const SizedBox(height: 4),
              Text(
                field.errorText!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
