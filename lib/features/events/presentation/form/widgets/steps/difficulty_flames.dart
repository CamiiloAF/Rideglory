import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Row of 5 flame icons indicating event difficulty level (1–5).
class DifficultyFlames extends StatelessWidget {
  const DifficultyFlames({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < level;
        return Icon(
          Icons.local_fire_department,
          size: 14,
          color: isActive
              ? AppColors.primary
              : AppColors.textOnDarkTertiary.withValues(alpha: 0.3),
        );
      }),
    );
  }
}
