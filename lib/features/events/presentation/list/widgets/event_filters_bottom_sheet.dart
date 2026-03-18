import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_filter_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
                      context.l10n.event_filters,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppTextButton(
                      label: context.l10n.event_clearFilters,
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
                        context.l10n.event_filterByType,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapSm,
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
                      AppSpacing.gapLg,
                      // Difficulty filter
                      Text(
                        context.l10n.event_filterByDifficulty,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapSm,
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
                      AppSpacing.gapLg,
                      // City filter
                      AppCityAutocomplete(
                        name: EventFilterFormFields.city,
                        labelText: context.l10n.event_filterByCity,
                        isRequired: false,
                      ),
                      AppSpacing.gapLg,
                      // Date range
                      Text(
                        context.l10n.event_filterByDateRange,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Row(
                        children: [
                          Expanded(
                            child: AppDatePicker(
                              fieldName: EventFilterFormFields.startDate,
                              labelText: context.l10n.event_startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            ),
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: AppDatePicker(
                              fieldName: EventFilterFormFields.endDate,
                              labelText: context.l10n.event_endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapLg,
                      // Boolean filters
                      AppCheckbox(
                        name: EventFilterFormFields.freeOnly,
                        title: context.l10n.event_filterByFreeOnly,
                      ),
                      AppCheckbox(
                        name: EventFilterFormFields.multiBrandOnly,
                        title: context.l10n.event_filterByMultiBrand,
                      ),
                      AppSpacing.gapXxl,
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
                  label: context.l10n.event_applyFilters,
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
