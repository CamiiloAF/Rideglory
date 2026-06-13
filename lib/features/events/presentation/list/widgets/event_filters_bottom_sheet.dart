import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_filter_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_difficulty_filter_chip.dart';
import 'package:rideglory/shared/widgets/filter/filter_cta_bar.dart';
import 'package:rideglory/shared/widgets/filter/filter_divider.dart';
import 'package:rideglory/shared/widgets/filter/filter_handle_bar.dart';
import 'package:rideglory/shared/widgets/filter/filter_panel_header.dart';
import 'package:rideglory/shared/widgets/filter/filter_section_label.dart';
import 'package:rideglory/shared/widgets/filter/filter_type_chip.dart';
import 'package:rideglory/shared/widgets/form/app_switch_tile.dart';

/// Events filter bottom sheet. Reuses the shared `filter_sheet` components so it
/// matches the maintenance filter design (handle, header, chips, CTA bar) per
/// issue #29.
class EventFiltersBottomSheet extends StatefulWidget {
  const EventFiltersBottomSheet({super.key, required this.cubitContext});

  final BuildContext cubitContext;

  static Future<void> show({required BuildContext context}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.darkBgPrimary.withValues(alpha: 0.82),
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

  EventsCubit get _cubit => widget.cubitContext.read<EventsCubit>();

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(_cubit.filters.types);
    _selectedDifficulties = Set.from(_cubit.filters.difficulties);
  }

  int get _activeCount =>
      _selectedTypes.length + _selectedDifficulties.length;

  void _clearAll() {
    setState(() {
      _selectedTypes = {};
      _selectedDifficulties = {};
    });
    // Clear to empty (not reset-to-initial) so an existing filter is wiped.
    final form = _formKey.currentState;
    form?.fields[EventFilterFormFields.startDate]?.didChange(null);
    form?.fields[EventFilterFormFields.endDate]?.didChange(null);
    form?.fields[EventFilterFormFields.freeOnly]?.didChange(false);
    form?.fields[EventFilterFormFields.multiBrandOnly]?.didChange(false);
  }

  void _apply() {
    _formKey.currentState?.save();
    final values = _formKey.currentState?.value ?? {};
    _cubit.updateFilters(
      EventFilters(
        types: _selectedTypes,
        difficulties: _selectedDifficulties,
        startDate: values[EventFilterFormFields.startDate] as DateTime?,
        endDate: values[EventFilterFormFields.endDate] as DateTime?,
        freeOnly: values[EventFilterFormFields.freeOnly] as bool? ?? false,
        multiBrandOnly:
            values[EventFilterFormFields.multiBrandOnly] as bool? ?? false,
      ),
    );
    // Custom: Navigator.pop closes the showModalBottomSheet route, not a
    // go_router route.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.darkBorderPrimary),
          left: BorderSide(color: AppColors.darkBorderPrimary),
          right: BorderSide(color: AppColors.darkBorderPrimary),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FilterHandleBar(),
            FilterPanelHeader(
              hasActiveFilters: true,
              onClearAll: _clearAll,
            ),
            const FilterDivider(),
            Flexible(
              child: SingleChildScrollView(
                child: FormBuilder(
                  key: _formKey,
                  initialValue: {
                    EventFilterFormFields.freeOnly: _cubit.filters.freeOnly,
                    EventFilterFormFields.multiBrandOnly:
                        _cubit.filters.multiBrandOnly,
                    EventFilterFormFields.startDate: _cubit.filters.startDate,
                    EventFilterFormFields.endDate: _cubit.filters.endDate,
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilterSectionLabel(context.l10n.event_filterByType),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: EventType.values.map((type) {
                                final isSelected = _selectedTypes.contains(type);
                                return FilterTypeChip(
                                  label: type.label,
                                  isSelected: isSelected,
                                  onTap: () => setState(() {
                                    isSelected
                                        ? _selectedTypes.remove(type)
                                        : _selectedTypes.add(type);
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const FilterDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilterSectionLabel(
                              context.l10n.event_filterByDifficulty,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: EventDifficulty.values.map((diff) {
                                final isSelected =
                                    _selectedDifficulties.contains(diff);
                                return EventDifficultyFilterChip(
                                  difficulty: diff,
                                  isSelected: isSelected,
                                  onTap: () => setState(() {
                                    isSelected
                                        ? _selectedDifficulties.remove(diff)
                                        : _selectedDifficulties.add(diff);
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const FilterDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FilterSectionLabel(
                              context.l10n.event_filterByDateRange,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppDatePicker(
                                    fieldName: EventFilterFormFields.startDate,
                                    labelText: context.l10n.event_startDate,
                                    hintText: context.l10n.event_filterDateHint,
                                    prefixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                    ),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppDatePicker(
                                    fieldName: EventFilterFormFields.endDate,
                                    labelText: context.l10n.event_endDate,
                                    hintText: context.l10n.event_filterDateHint,
                                    prefixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                    ),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const FilterDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Column(
                          children: [
                            AppSwitchTile(
                              name: EventFilterFormFields.freeOnly,
                              title: context.l10n.event_filterByFreeOnly,
                            ),
                            AppSwitchTile(
                              name: EventFilterFormFields.multiBrandOnly,
                              title: context.l10n.event_filterByMultiBrand,
                            ),
                          ],
                        ),
                      ),
                      const FilterDivider(),
                    ],
                  ),
                ),
              ),
            ),
            FilterCtaBar(
              activeFilterCount: _activeCount,
              secondaryLabel: context.l10n.cancel,
              onSecondary: () => Navigator.pop(context),
              onApply: _apply,
            ),
          ],
        ),
      ),
    );
  }
}
