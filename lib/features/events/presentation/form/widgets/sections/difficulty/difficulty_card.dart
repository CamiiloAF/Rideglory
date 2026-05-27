import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/difficulty/flame_selector.dart';

class DifficultyCard extends StatelessWidget {
  const DifficultyCard({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final EventDifficulty selected;
  final void Function(EventDifficulty) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.event_form_difficulty_level_label,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDarkPrimary,
                ),
              ),
              FlameSelector(selected: selected, onSelect: onSelect),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.event_form_difficulty_description(
              selected.value.toString(),
            ),
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: AppColors.textOnDarkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
