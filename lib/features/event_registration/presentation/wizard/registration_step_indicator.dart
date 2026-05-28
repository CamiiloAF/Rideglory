import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Progress indicator for the registration wizard: numbered step dots joined by
/// connector lines. The active and completed dots are highlighted in the brand
/// accent color, matching the Pencil `dotsRow` design.
class RegistrationStepIndicator extends StatelessWidget {
  const RegistrationStepIndicator({
    super.key,
    required this.stepCount,
    required this.currentStep,
  });

  final int stepCount;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < stepCount; index++) {
      final isReached = index <= currentStep;
      children.add(
        _RegistrationStepDot(label: index + 1, isReached: isReached),
      );
      if (index < stepCount - 1) {
        children.add(
          Expanded(
            child: _RegistrationStepConnector(isReached: index < currentStep),
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class _RegistrationStepDot extends StatelessWidget {
  const _RegistrationStepDot({required this.label, required this.isReached});

  final int label;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isReached ? AppColors.primary : AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        '$label',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)
            .copyWith(
              color: isReached
                  ? AppColors.darkBgPrimary
                  : AppColors.textOnDarkTertiary,
            ),
      ),
    );
  }
}

class _RegistrationStepConnector extends StatelessWidget {
  const _RegistrationStepConnector({required this.isReached});

  final bool isReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      color: isReached ? AppColors.primary : AppColors.darkTertiary,
    );
  }
}
