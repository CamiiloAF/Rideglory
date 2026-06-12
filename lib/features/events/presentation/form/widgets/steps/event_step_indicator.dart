import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/step_circle.dart';

/// 4-step progress indicator for the event creation wizard.
///
/// - Completed step: orange fill + check mark + [AppColors.darkBgPrimary] text
/// - Active step: orange fill + step number + [AppColors.darkBgPrimary] text
/// - Future step: [colorScheme.surfaceContainerHighest] + step number +
///   [colorScheme.onSurfaceVariant] text
class EventStepIndicator extends StatelessWidget {
  const EventStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;
          return Expanded(
            child: StepCircle(
              stepNumber: index + 1,
              isCompleted: isCompleted,
              isActive: isActive,
              showConnector: index < totalSteps - 1,
            ),
          );
        }),
      ),
    );
  }
}
