import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/step_circle.dart';

/// 4-step progress indicator for the event creation wizard.
///
/// Design spec (Pencil AybHb):
/// - Each step = circle (30×30) + label below, arranged horizontally
/// - Completed: orange fill + check + label white w500
/// - Active: orange fill + number + label white w700 + outer glow #2D2117
/// - Future: dark fill #1A1A1F + inner border #2A2A32 + label gray #6B7280 w500
/// - Connectors: 2px line, orange if completed, #2A2A32 otherwise
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
    final labels = [
      context.l10n.event_step_basicInfo,
      context.l10n.event_step_details,
      context.l10n.event_step_route,
      context.l10n.event_step_reviewAndPublish,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;
          final label = index < labels.length ? labels[index] : '${index + 1}';
          return Expanded(
            child: StepCircle(
              stepNumber: index + 1,
              label: label,
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
