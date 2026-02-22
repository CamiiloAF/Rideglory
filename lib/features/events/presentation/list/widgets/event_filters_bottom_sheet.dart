import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_filter_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_checkbox.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFiltersBottomSheet extends StatefulWidget {
  const EventFiltersBottomSheet({super.key, required this.cubitContext});

  final BuildContext cubitContext;

  static Future<void> show({required BuildContext context}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFiltersBottomSheet(cubitContext: context),
    );
  }

  @override
  State<EventFiltersBottomSheet> createState() =>
      _EventFiltersBottomSheetState();
}

class _EventFiltersBottomSheetState extends State<EventFiltersBottomSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  late Set<EventType> _selectedTypes;
  late Set<EventDifficulty> _selectedDifficulties;

  @override
  void initState() {
    super.initState();
    final cubit = widget.cubitContext.read<EventsCubit>();
    _selectedTypes = Set.from(cubit.filters.types);
    _selectedDifficulties = Set.from(cubit.filters.difficulties);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = widget.cubitContext.read<EventsCubit>();

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
          key: _formKey,
          initialValue: {
            EventFilterFormFields.city: cubit.filters.city ?? '',
            EventFilterFormFields.freeOnly: cubit.filters.freeOnly,
            EventFilterFormFields.multiBrandOnly: cubit.filters.multiBrandOnly,
            EventFilterFormFields.startDate: cubit.filters.startDate,
            EventFilterFormFields.endDate: cubit.filters.endDate,
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
                    AppTextButton(
                      label: EventStrings.clearFilters,
                      onPressed: () {
                        setState(() {
                          _selectedTypes.clear();
                          _selectedDifficulties.clear();
                        });
                        _formKey.currentState?.reset();
                        cubit.clearFilters();
                        Navigator.of(context).pop();
                      },
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
                      Wrap(
                        spacing: 8,
                        children: EventType.values.map((type) {
                          final selected = _selectedTypes.contains(type);
                          return FilterChip(
                            label: Text(type.label),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                selected
                                    ? _selectedTypes.remove(type)
                                    : _selectedTypes.add(type);
                              });
                            },
                          );
                        }).toList(),
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
                      Wrap(
                        spacing: 8,
                        children: EventDifficulty.values.map((diff) {
                          final selected = _selectedDifficulties.contains(diff);
                          return FilterChip(
                            label: Text('🌶' * diff.value),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                selected
                                    ? _selectedDifficulties.remove(diff)
                                    : _selectedDifficulties.add(diff);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // City filter
                      AppTextField(
                        name: EventFilterFormFields.city,
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
                              fieldName: EventFilterFormFields.startDate,
                              labelText: EventStrings.startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppDatePicker(
                              fieldName: EventFilterFormFields.endDate,
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
                        name: EventFilterFormFields.freeOnly,
                        title: EventStrings.filterByFreeOnly,
                      ),
                      AppCheckbox(
                        name: EventFilterFormFields.multiBrandOnly,
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
                child: AppButton(
                  label: EventStrings.applyFilters,
                  onPressed: () {
                    _formKey.currentState?.save();
                    final values = _formKey.currentState?.value ?? {};

                    final filters = EventFilters(
                      types: _selectedTypes,
                      difficulties: _selectedDifficulties,
                      city: values[EventFilterFormFields.city] as String?,
                      startDate:
                          values[EventFilterFormFields.startDate] as DateTime?,
                      endDate:
                          values[EventFilterFormFields.endDate] as DateTime?,
                      freeOnly:
                          values[EventFilterFormFields.freeOnly] as bool? ??
                          false,
                      multiBrandOnly:
                          values[EventFilterFormFields.multiBrandOnly]
                              as bool? ??
                          false,
                    );

                    cubit.updateFilters(filters);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
