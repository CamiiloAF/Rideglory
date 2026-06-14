import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class FlameSelector extends StatelessWidget {
  const FlameSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final EventDifficulty selected;
  final void Function(EventDifficulty) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final level = EventDifficulty.values[i];
        final filled = i < selected.value;
        return GestureDetector(
          onTap: () => onSelect(level),
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: Icon(
              LucideIcons.flame,
              size: 28,
              color: filled ? AppColors.primary : AppColors.darkBorderLight,
            ),
          ),
        );
      }),
    );
  }
}
