import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
            _DifficultyCard(selected: selected, onSelect: field.didChange),
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

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.selected, required this.onSelect});

  final EventDifficulty selected;
  final void Function(EventDifficulty) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.event_form_difficulty_level_label,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDarkPrimary,
                ),
              ),
              _FlameSelector(selected: selected, onSelect: onSelect),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.event_form_difficulty_description(
              selected.value.toString(),
            ),
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: AppColors.textOnDarkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlameSelector extends StatelessWidget {
  const _FlameSelector({required this.selected, required this.onSelect});

  final EventDifficulty selected;
  final void Function(EventDifficulty) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final level = EventDifficulty.values[i];
        final filled = i < selected.value;
        return GestureDetector(
          onTap: () => onSelect(level),
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: Icon(
              LucideIcons.flame,
              size: 28,
              color: filled
                  ? AppColors.primary
                  : AppColors.darkBorderPrimary,
            ),
          ),
        );
      }),
    );
  }
}
