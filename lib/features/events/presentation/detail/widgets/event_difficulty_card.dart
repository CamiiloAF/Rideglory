import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventDifficultyCard extends StatelessWidget {
  const EventDifficultyCard({super.key, required this.difficulty});

  final EventDifficulty difficulty;

  static String _label(EventDifficulty d) => switch (d) {
    EventDifficulty.one => 'Fácil',
    EventDifficulty.two => 'Moderado',
    EventDifficulty.three => 'Intermedio',
    EventDifficulty.four => 'Difícil',
    EventDifficulty.five => 'Muy difícil',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NIVEL DE DIFICULTAD',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _label(difficulty),
                style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.local_fire_department,
                size: 26,
                color: i < difficulty.value
                    ? Colors.redAccent
                    : AppColors.darkTextSecondary.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
