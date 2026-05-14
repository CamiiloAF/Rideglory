import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    super.key,
    required this.eventsLabel,
    required this.kmLabel,
    required this.followersLabel,
    this.eventsCount = 0,
    this.kmCount = 0,
    this.followersCount = 0,
  });

  final String eventsLabel;
  final String kmLabel;
  final String followersLabel;
  final int eventsCount;
  final int kmCount;
  final int followersCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCell(value: eventsCount.toString(), label: eventsLabel),
        _StatDivider(),
        _StatCell(value: kmCount.toString(), label: kmLabel),
        _StatDivider(),
        _StatCell(value: followersCount.toString(), label: followersLabel),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDarkPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 8);
  }
}
