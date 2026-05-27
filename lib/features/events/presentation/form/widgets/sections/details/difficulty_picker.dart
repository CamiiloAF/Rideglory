import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  final EventDifficulty selected;
  final Map<EventDifficulty, String> labels;
  final void Function(EventDifficulty) onChanged;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<EventDifficulty>(
      name: EventFormFields.difficulty,
      validator: FormBuilderValidators.required(
        errorText: context.l10n.event_difficultyRequired,
      ),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_difficulty,
              style: TextStyle(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.gapSm,
            Row(
              children: [
                Row(
                  children: List.generate(5, (i) {
                    final level = EventDifficulty.values[i];
                    final filled = i < selected.value;
                    return GestureDetector(
                      onTap: () {
                        onChanged(level);
                        field.didChange(level);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          Icons.local_fire_department,
                          size: 34,
                          color: filled
                              ? context.colorScheme.primary
                              : context.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                ),
                AppSpacing.hGapMd,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labels[selected] ?? '',
                    style: TextStyle(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
