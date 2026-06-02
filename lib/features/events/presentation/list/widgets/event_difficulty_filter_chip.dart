import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// Difficulty filter chip matching the Pencil "Eventos — Filtros Sheet" design:
/// the unified difficulty icon ([Icons.local_fire_department]) + "X{level}" +
/// short label. Selected state uses an accent border + subtle accent fill.
class EventDifficultyFilterChip extends StatelessWidget {
  const EventDifficultyFilterChip({
    super.key,
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final EventDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primarySubtle : AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.darkBorderPrimary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: AppColors.primary,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'X${difficulty.value}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              difficulty.shortLabel,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
