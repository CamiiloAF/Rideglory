import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// A single step circle (with optional connector line) for [EventStepIndicator].
class StepCircle extends StatelessWidget {
  const StepCircle({
    super.key,
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.showConnector,
  });

  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFuture = !isCompleted && !isActive;

    final bgColor = isFuture
        ? colorScheme.surfaceContainerHighest
        : AppColors.primary;

    final fgColor = isFuture
        ? colorScheme.onSurfaceVariant
        : AppColors.darkBgPrimary;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? Icon(Icons.check, size: 14, color: fgColor)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
        ),
        if (showConnector)
          Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? AppColors.primary
                  : colorScheme.surfaceContainerHighest,
            ),
          ),
      ],
    );
  }
}
