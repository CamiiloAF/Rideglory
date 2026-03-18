import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filter_chip.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventTypeFilterChips extends StatelessWidget {
  const EventTypeFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EventsCubit>();
    final selectedTypes = cubit.filters.types;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          EventFilterChip(
            label: context.l10n.event_filterAll,
            isSelected: selectedTypes.isEmpty,
            onTap: () {
              cubit.updateFilters(cubit.filters.copyWith(types: {}));
            },
          ),
          SizedBox(width: 10),
          ...EventType.values.map((type) {
            final isSelected = selectedTypes.contains(type);
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: EventFilterChip(
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
              ),
            );
          }),
        ],
      ),
    );
  }
}
