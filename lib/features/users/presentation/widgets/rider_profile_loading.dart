import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class RiderProfileLoading extends StatelessWidget {
  const RiderProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerColor = colorScheme.surfaceContainerHighest;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: shimmerColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        AppSpacing.gapMd,
        Center(
          child: Container(
            width: 160,
            height: 20,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        AppSpacing.gapSm,
        Center(
          child: Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        AppSpacing.gapXl,
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        AppSpacing.gapMd,
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        AppSpacing.gapMd,
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
