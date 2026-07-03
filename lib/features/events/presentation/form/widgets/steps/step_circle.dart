import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// A single step column (circle + label, with optional connector) for [EventStepIndicator].
///
/// Design spec (Pencil AybHb / EzQtb / XbcHD / FW3Hd):
/// - Circle: 30×30, cornerRadius 15
/// - Active / completed: fill #F98C1F, outer stroke #2D2117 w=3
/// - Future: fill #1A1A1F, inner stroke #2A2A32 w=1
/// - Label: 11px, w700 active/completed (#FFFFFF), w500 future (#6B7280)
/// - Connector: 2px, orange if completed, #2A2A32 if future
class StepCircle extends StatelessWidget {
  const StepCircle({
    super.key,
    required this.stepNumber,
    required this.label,
    required this.isCompleted,
    required this.isActive,
  });

  final int stepNumber;
  final String label;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isFuture = !isCompleted && !isActive;

    final bgColor = isFuture ? AppColors.darkBgSecondary : AppColors.primary;
    const fgColor = AppColors.darkBgPrimary;
    final labelColor = isFuture
        ? AppColors.textOnDarkTertiary
        : AppColors.textOnDarkPrimary;
    final labelWeight = (isActive && !isCompleted)
        ? FontWeight.w700
        : FontWeight.w500;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isFuture
                ? Border.all(color: AppColors.darkBorderPrimary, width: 1)
                : null,
            boxShadow: !isFuture
                ? const [
                    BoxShadow(
                      color: AppColors.primarySubtle,
                      spreadRadius: 3,
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: fgColor)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isFuture ? AppColors.textOnDarkTertiary : fgColor,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: labelWeight,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
