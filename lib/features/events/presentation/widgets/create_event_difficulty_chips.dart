import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../domain/event_difficulty.dart';
import '../event_labels.dart';

/// Selector de dificultad de EV3 (paso 2): tres chips exclusivos.
class CreateEventDifficultyChips extends StatelessWidget {
  const CreateEventDifficultyChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final EventDifficulty selected;
  final ValueChanged<EventDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        for (final difficulty in EventDifficulty.values) ...[
          if (difficulty != EventDifficulty.values.first)
            const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onSelected(difficulty),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: difficulty == selected
                      ? colors.accentSoft
                      : colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: difficulty == selected
                        ? colors.accent
                        : colors.borderStrong,
                  ),
                ),
                child: Text(
                  eventDifficultyLabel(context, difficulty),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
