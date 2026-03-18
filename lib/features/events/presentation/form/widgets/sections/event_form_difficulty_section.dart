import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_section_card.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventFormDifficultySection extends StatelessWidget {
  const EventFormDifficultySection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EventFormSectionCard(
      icon: Icons.local_fire_department,
      title: context.l10n.event_rideDifficulty,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FormBuilderField<EventDifficulty>(
          name: EventFormFields.difficulty,

          validator: FormBuilderValidators.required(
            errorText: context.l10n.event_difficultyRequired,
          ),
          builder: (field) {
            final selected = field.value ?? EventDifficulty.one;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final level = EventDifficulty.values[i];
                        final filled = i < selected.value;
                        return GestureDetector(
                          onTap: () => field.didChange(level),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.local_fire_department,
                              size: 34,
                              color: filled
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.35),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        context.l10n.event_difficultyLevel(
                          selected.value.toString(),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (field.hasError) ...[
                  SizedBox(height: 6),
                  Text(
                    field.errorText!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
