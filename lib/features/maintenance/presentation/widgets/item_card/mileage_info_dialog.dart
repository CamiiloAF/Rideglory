import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Info-only modal showing the vehicle's current mileage. Uses the unified
/// [AppModal] design with the mileage value rendered as a custom body chip.
class MileageInfoDialog extends StatelessWidget {
  final Color typeColor;
  final int? currentMileage;
  final String distanceUnitLabel;

  const MileageInfoDialog({
    super.key,
    required this.typeColor,
    required this.currentMileage,
    required this.distanceUnitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppModal(
      title: context.l10n.maintenance_currentMileage,
      icon: Icons.speed_rounded,
      iconColor: typeColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${currentMileage?.toStringAsFixed(0) ?? '-'} $distanceUnitLabel',
          style: context.headlineMedium?.copyWith(
            color: typeColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
