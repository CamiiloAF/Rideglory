import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/max_participants/max_participants_card_labels.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/max_participants/max_participants_stepper.dart';

class MaxParticipantsCard extends StatelessWidget {
  const MaxParticipantsCard({
    super.key,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
    required this.onManualChange,
  });

  final int? count;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final void Function(int?) onManualChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const MaxParticipantsCardLabels(),
          const SizedBox(width: 12),
          Expanded(
            child: MaxParticipantsStepper(
              count: count,
              onDecrement: onDecrement,
              onIncrement: onIncrement,
              onManualChange: onManualChange,
            ),
          ),
        ],
      ),
    );
  }
}
