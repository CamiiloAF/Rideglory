import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_checkbox.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

// TODO Refactor to separate widget
class EventFiltersBottomSheet extends StatelessWidget {
  final EventFilters initialFilters;

  const EventFiltersBottomSheet({super.key, required this.initialFilters});

  static Future<EventFilters?> show({
    required BuildContext context,
    required EventFilters initialFilters,
  }) {
    return showModalBottomSheet<EventFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFiltersBottomSheet(initialFilters: initialFilters),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FormBuilder(
          key: formKey,
          initialValue: {
            // TODO Improve keys access
            'city': initialFilters.city ?? '',
            'freeOnly': initialFilters.freeOnly,
            'multiBrandOnly': initialFilters.multiBrandOnly,
            'startDate': initialFilters.startDate,
            'endDate': initialFilters.endDate,
          },
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      EventStrings.filters,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(const EventFilters());
                      },
                      child: const Text(EventStrings.clearFilters),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Filters content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event type filter
                      Text(
                        EventStrings.filterByType,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _EventTypeFilterChips(
                        selectedTypes: initialFilters.types,
                      ),
                      const SizedBox(height: 16),
                      // Difficulty filter
                      Text(
                        EventStrings.filterByDifficulty,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DifficultyFilterChips(
                        selectedDifficulties: initialFilters.difficulties,
                      ),
                      const SizedBox(height: 16),
                      // City filter
                      AppTextField(
                        name: 'city',
                        labelText: EventStrings.filterByCity,
                        prefixIcon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 16),
                      // Date range
                      Text(
                        EventStrings.filterByDateRange,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppDatePicker(
                              fieldName: 'startDate',
                              labelText: EventStrings.startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppDatePicker(
                              fieldName: 'endDate',
                              labelText: EventStrings.endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Boolean filters
                      AppCheckbox(
                        name: 'freeOnly',
                        title: EventStrings.filterByFreeOnly,
                      ),
                      AppCheckbox(
                        name: 'multiBrandOnly',
                        title: EventStrings.filterByMultiBrand,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Apply button
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      formKey.currentState?.save();
                      final values = formKey.currentState?.value ?? {};

                      final typeChipState = _typeFilterKey.currentState;
                      final diffChipState = _diffFilterKey.currentState;

                      Navigator.of(context).pop(
                        EventFilters(
                          types:
                              typeChipState?.selectedTypes ??
                              initialFilters.types,
                          difficulties:
                              diffChipState?.selectedDifficulties ??
                              initialFilters.difficulties,
                          city: values['city'] as String?,
                          startDate: values['startDate'] as DateTime?,
                          endDate: values['endDate'] as DateTime?,
                          freeOnly: values['freeOnly'] as bool? ?? false,
                          multiBrandOnly:
                              values['multiBrandOnly'] as bool? ?? false,
                        ),
                      );
                    },
                    child: const Text(EventStrings.applyFilters),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _typeFilterKey = GlobalKey<_EventTypeFilterChipsState>();
  static final _diffFilterKey = GlobalKey<_DifficultyFilterChipsState>();
}

class _EventTypeFilterChips extends StatefulWidget {
  final Set<EventType> selectedTypes;

  const _EventTypeFilterChips({required this.selectedTypes});

  @override
  State<_EventTypeFilterChips> createState() => _EventTypeFilterChipsState();
}

class _EventTypeFilterChipsState extends State<_EventTypeFilterChips> {
  late Set<EventType> selectedTypes;

  @override
  void initState() {
    super.initState();
    selectedTypes = Set.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: EventType.values.map((type) {
        final selected = selectedTypes.contains(type);
        return FilterChip(
          label: Text(type.label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              selected ? selectedTypes.remove(type) : selectedTypes.add(type);
            });
          },
        );
      }).toList(),
    );
  }
}

class _DifficultyFilterChips extends StatefulWidget {
  final Set<EventDifficulty> selectedDifficulties;

  const _DifficultyFilterChips({required this.selectedDifficulties});

  @override
  State<_DifficultyFilterChips> createState() => _DifficultyFilterChipsState();
}

class _DifficultyFilterChipsState extends State<_DifficultyFilterChips> {
  late Set<EventDifficulty> selectedDifficulties;

  @override
  void initState() {
    super.initState();
    selectedDifficulties = Set.from(widget.selectedDifficulties);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: EventDifficulty.values.map((diff) {
        final selected = selectedDifficulties.contains(diff);
        return FilterChip(
          label: Text('🌶' * diff.value),
          selected: selected,
          onSelected: (_) {
            setState(() {
              selected
                  ? selectedDifficulties.remove(diff)
                  : selectedDifficulties.add(diff);
            });
          },
        );
      }).toList(),
    );
  }
}
