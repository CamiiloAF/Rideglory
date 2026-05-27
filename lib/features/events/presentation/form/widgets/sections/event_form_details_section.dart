import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/data/colombia_motos_brands_data.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/details/difficulty_picker.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/details/event_type_picker.dart';

class EventFormDetailsSection extends StatefulWidget {
  const EventFormDetailsSection({super.key});

  @override
  State<EventFormDetailsSection> createState() =>
      _EventFormDetailsSectionState();
}

class _EventFormDetailsSectionState extends State<EventFormDetailsSection> {
  EventDifficulty _selectedDifficulty = EventDifficulty.one;
  EventType _selectedEventType = EventType.urban;

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
        DifficultyPicker(
          selected: _selectedDifficulty,
          labels: _difficultyLabels,
          onChanged: (level) => setState(() => _selectedDifficulty = level),
        ),
        AppSpacing.gapXxl,
        EventTypePicker(
          selected: _selectedEventType,
          onChanged: (type) => setState(() => _selectedEventType = type),
        ),
        AppSpacing.gapXxl,
        AppAutocompleteChipsField(
          name: EventFormFields.allowedBrands,
          labelText: context.l10n.event_allowedBrands,
          hintText: context.l10n.event_allowedBrandsHint,
          helperText: context.l10n.event_allowedBrandsHelper,
          suggestions: ColombiaMotosBrandsData.search,
          initialValue:
              context.read<EventFormCubit>().editingEvent?.allowedBrands ?? [],
        ),
        AppSpacing.gapLg,
        AppTextField(
          name: EventFormFields.price,
          labelText: context.l10n.event_price,
          prefixText: '\$',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            final parsed = double.tryParse(value);
            if (parsed == null) return context.l10n.event_invalidPrice;
            return null;
          },
        ),
      ],
    );
  }
}
