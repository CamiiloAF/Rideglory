import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class DifficultyChip extends StatelessWidget {
  final EventDifficulty difficulty;

  const DifficultyChip({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.appColors.difficultyChip.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('🌶' * difficulty.value, style: theme.textTheme.labelSmall),
    );
  }
}
