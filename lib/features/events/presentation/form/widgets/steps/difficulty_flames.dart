import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Row of flame icons indicating event difficulty level in the review card.
///
/// Design spec (Pencil FW3Hd — Ynzjg difficultyDisplay):
/// - Size 16px, gap 3px between flames
/// - Active: AppColors.primary (#F98C1F)
/// - Inactive: AppColors.darkBorderLight (#3A3A44)
class DifficultyFlames extends StatelessWidget {
  const DifficultyFlames({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < level;
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
          child: Icon(
            Icons.local_fire_department,
            size: 16,
            color: isActive ? AppColors.primary : AppColors.darkBorderLight,
          ),
        );
      }),
    );
  }
}
