import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventFormDetailsSection extends StatefulWidget {
  const EventFormDetailsSection({super.key});

  @override
  State<EventFormDetailsSection> createState() =>
      _EventFormDetailsSectionState();
}

class _EventFormDetailsSectionState extends State<EventFormDetailsSection> {
  EventDifficulty _selectedDifficulty = EventDifficulty.one;
  EventType _selectedEventType = EventType.onRoad;

  static const _difficultyLabels = {
    EventDifficulty.one: 'Fácil',
    EventDifficulty.two: 'Moderado',
    EventDifficulty.three: 'Intermedio',
    EventDifficulty.four: 'Difícil',
    EventDifficulty.five: 'Muy difícil',
  };

  @override
  void initState() {
    super.initState();
    final editingEvent = context.read<EventFormCubit>().editingEvent;
    if (editingEvent != null) {
      _selectedDifficulty = editingEvent.difficulty;
      _selectedEventType = editingEvent.eventType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DifficultyPicker(
          selected: _selectedDifficulty,
          labels: _difficultyLabels,
          onChanged: (level) => setState(() => _selectedDifficulty = level),
        ),
        AppSpacing.gapXxl,
        _EventTypePicker(
          selected: _selectedEventType,
          onChanged: (type) => setState(() => _selectedEventType = type),
        ),
        AppSpacing.gapXxl,
        AppAutocompleteChipsField(
          name: EventFormFields.allowedBrands,
          labelText: context.l10n.event_allowedBrands,
          hintText: context.l10n.event_allowedBrandsHint,
          helperText: context.l10n.event_allowedBrandsHelper,
          prefixIcon: Icons.shield_outlined,
          suggestions: ColombiaMotosBrandsData.search,
          initialValue:
              context.read<EventFormCubit>().editingEvent?.allowedBrands ?? [],
        ),
        AppSpacing.gapLg,
        AppTextField(
          name: EventFormFields.price,
          labelText: context.l10n.event_price,
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.numeric(
              errorText: context.l10n.event_invalidPrice,
              checkNullOrEmpty: false,
            ),
          ]),
        ),
      ],
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({
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
                              : context.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
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

class _EventTypePicker extends StatelessWidget {
  const _EventTypePicker({required this.selected, required this.onChanged});

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
                        color: isSelected
                            ? Colors.white
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
