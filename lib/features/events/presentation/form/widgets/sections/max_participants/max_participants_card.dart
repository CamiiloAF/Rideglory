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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: MaxParticipantsCardLabels()),
          MaxParticipantsStepper(
            count: count,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
            onManualChange: onManualChange,
          ),
        ],
      ),
    );
  }
}
