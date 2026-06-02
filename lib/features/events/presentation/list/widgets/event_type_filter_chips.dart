import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filter_chip.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventTypeFilterChips extends StatelessWidget {
  const EventTypeFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EventsCubit>();
    final selectedTypes = cubit.filters.types;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: EventType.values.length + 1,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          if (index == 0) {
            return EventFilterChip(
              label: context.l10n.event_filterAll,
              isSelected: selectedTypes.isEmpty,
              onTap: () =>
                  cubit.updateFilters(cubit.filters.copyWith(types: {})),
            );
          }
          final type = EventType.values[index - 1];
          final isSelected = selectedTypes.contains(type);
          return EventFilterChip(
            label: type.label,
            isSelected: isSelected,
            onTap: () {
              final newTypes = Set<EventType>.from(selectedTypes);
              if (isSelected) {
                newTypes.remove(type);
              } else {
                newTypes.add(type);
              }
              cubit.updateFilters(cubit.filters.copyWith(types: newTypes));
            },
          );
        },
      ),
    );
  }
}
