import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';

class EventTypeFilterChips extends StatelessWidget {
  const EventTypeFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EventsCubit>();
    final selectedTypes = cubit.filters.types;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Todos',
            isSelected: selectedTypes.isEmpty,
            onTap: () {
              cubit.updateFilters(cubit.filters.copyWith(types: {}));
            },
          ),
          const SizedBox(width: 8),
          ...EventType.values.map((type) {
            final isSelected = selectedTypes.contains(type);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[700]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
