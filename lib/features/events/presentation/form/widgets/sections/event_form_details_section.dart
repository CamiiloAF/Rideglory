import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_chips_input.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFormDetailsSection extends StatefulWidget {
  const EventFormDetailsSection({super.key});

  @override
  State<EventFormDetailsSection> createState() =>
      _EventFormDetailsSectionState();
}

class _EventFormDetailsSectionState extends State<EventFormDetailsSection> {
  EventDifficulty _selectedDifficulty = EventDifficulty.one;
  EventType _selectedEventType = EventType.onRoad;

  @override
  void initState() {
    super.initState();
    final state = context.read<EventFormCubit>().state;
    state.whenOrNull(
      editing: (event) {
        _selectedDifficulty = event.difficulty;
        _selectedEventType = event.eventType;
      },
    );
  }

  static const _difficultyLabels = {
    EventDifficulty.one: 'Fácil',
    EventDifficulty.two: 'Moderado',
    EventDifficulty.three: 'Intermedio',
    EventDifficulty.four: 'Difícil',
    EventDifficulty.five: 'Muy difícil',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Difficulty ─────────────────────────────────────────
        Text(
          EventStrings.difficulty,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        FormBuilderField<EventDifficulty>(
          name: EventFormFields.difficulty,
          validator: FormBuilderValidators.required(
            errorText: EventStrings.difficultyRequired,
          ),
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Fire icon row
                    Row(
                      children: List.generate(5, (i) {
                        final level = EventDifficulty.values[i];
                        final filled = i < _selectedDifficulty.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDifficulty = level);
                            field.didChange(level);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.local_fire_department,
                              size: 34,
                              color: filled
                                  ? Colors.redAccent
                                  : cs.onSurface.withOpacity(0.2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _difficultyLabels[_selectedDifficulty] ?? '',
                        style: const TextStyle(
                          color: Colors.redAccent,
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
                        color: cs.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Event type ─────────────────────────────────────────
        Text(
          EventStrings.eventType,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        FormBuilderField<EventType>(
          name: EventFormFields.eventType,
          validator: FormBuilderValidators.required(
            errorText: EventStrings.eventTypeRequired,
          ),
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EventType.values.map((type) {
                    final selected = _selectedEventType == type;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedEventType = type);
                        field.didChange(type);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: selected
                                ? cs.primary
                                : cs.outlineVariant,
                          ),
                        ),
                        child: Text(
                          type.label,
                          style: TextStyle(
                            color: selected ? Colors.white : cs.onSurface,
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
                      style: TextStyle(color: cs.error, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Allowed brands ─────────────────────────────────────
        AppChipsInput(
          name: EventFormFields.allowedBrands,
          labelText: EventStrings.allowedBrands,
          hintText: EventStrings.allowedBrandsHint,
          helperText: EventStrings.allowedBrandsHelper,
          prefixIcon: Icons.shield_outlined,
          initialValue: context.read<EventFormCubit>().state.maybeWhen(
            editing: (event) => event.allowedBrands,
            orElse: () => [],
          ),
        ),

        const SizedBox(height: 16),

        // ── Price ──────────────────────────────────────────────
        AppTextField(
          name: EventFormFields.price,
          labelText: EventStrings.price,
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.numeric(
              errorText: EventStrings.invalidPrice,
              checkNullOrEmpty: false,
            ),
          ]),
        ),
      ],
    );
  }
}
