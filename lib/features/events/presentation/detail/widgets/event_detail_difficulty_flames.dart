import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class EventDetailDifficultyFlames extends StatelessWidget {
  const EventDetailDifficultyFlames({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < level;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.local_fire_department,
            size: 16,
            color: filled
                ? context.colorScheme.primary
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}
