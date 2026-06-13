import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
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

    final items = <Widget>[];
    for (int i = 0; i < totalSteps; i++) {
      final isCompleted = i < currentStep;
      final isActive = i == currentStep;
      final label = i < labels.length ? labels[i] : '${i + 1}';
      items.add(
        StepCircle(
          stepNumber: i + 1,
          label: label,
          isCompleted: isCompleted,
          isActive: isActive,
        ),
      );
      if (i < totalSteps - 1) {
        items.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(top: 14, bottom: 17),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.darkBorderPrimary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
}
