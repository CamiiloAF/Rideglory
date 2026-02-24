import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class DifficultyChip extends StatelessWidget {
  final EventDifficulty difficulty;

  const DifficultyChip({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.difficultyChip.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('🌶' * difficulty.value, style: theme.textTheme.labelSmall),
    );
  }
}
