import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
    EventType.tourism,
    EventType.urban,
    EventType.offRoad,
  ];

  static const _row2 = [
    EventType.competition,
    EventType.solidarity,
    EventType.shortDistance,
  ];

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<EventType>(
      name: EventFormFields.eventType,
      validator: FormBuilderValidators.required(
        errorText: context.l10n.event_eventTypeRequired,
      ),
      builder: (field) {
        final selected = field.value ?? EventType.tourism;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.gapMd,
            _EventTypeRow(
              types: _row1,
              selected: selected,
              onSelect: field.didChange,
            ),
            const SizedBox(height: 8),
            _EventTypeRow(
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

class _EventTypeRow extends StatelessWidget {
  const _EventTypeRow({
    required this.types,
    required this.selected,
    required this.onSelect,
  });

  final List<EventType> types;
  final EventType selected;
  final void Function(EventType) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: types
          .map(
            (type) => Padding(
              padding: EdgeInsets.only(right: type != types.last ? 8 : 0),
              child: _EventTypeChip(
                type: type,
                isSelected: selected == type,
                onTap: () => onSelect(type),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EventTypeChip extends StatelessWidget {
  const _EventTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final EventType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorderPrimary,
          ),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : AppColors.textOnDarkSecondary,
          ),
        ),
      ),
    );
  }
}
