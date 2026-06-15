import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// Pill de dificultad: llama-icon + "X{N}" + shortLabel.
/// Usado en la title row del Bottom Sheet card (Propuesta D).
class EventDetailDiffPill extends StatelessWidget {
  const EventDetailDiffPill({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final difficulty = event.difficulty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.flame, color: AppColors.primary, size: 12),
          const SizedBox(width: 4),
          Text(
            difficulty.shortLabel,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Space Grotesk',
            ),
          ),
        ],
      ),
    );
  }
}
