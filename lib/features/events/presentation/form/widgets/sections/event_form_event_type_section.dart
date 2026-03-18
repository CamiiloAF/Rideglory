import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class EventFormEventTypeSection extends StatelessWidget {
  const EventFormEventTypeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FormBuilderField<EventType>(
      name: EventFormFields.eventType,
      validator: FormBuilderValidators.required(
        errorText: EventStrings.eventTypeRequired,
      ),
      builder: (field) {
        final selected = field.value ?? EventType.onRoad;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventType.values.map((type) {
                final isSelected = selected == type;
                return GestureDetector(
                  onTap: () => field.didChange(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : context.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
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
    );
  }
}
