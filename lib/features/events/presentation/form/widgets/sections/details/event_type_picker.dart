import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventTypePicker extends StatelessWidget {
  const EventTypePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final EventType selected;
  final void Function(EventType) onChanged;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<EventType>(
      name: EventFormFields.eventType,
      validator: FormBuilderValidators.required(
        errorText: context.l10n.event_eventTypeRequired,
      ),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_eventType,
              style: TextStyle(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventType.values.map((type) {
                final isSelected = selected == type;
                return GestureDetector(
                  onTap: () {
                    onChanged(type);
                    field.didChange(type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      type.label,
                      style: TextStyle(
                        // Texto oscuro sobre el color primario (nunca blanco).
                        color: isSelected
                            ? AppColors.darkBgPrimary
                            : context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
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
