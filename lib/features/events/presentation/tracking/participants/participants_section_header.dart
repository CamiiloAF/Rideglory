import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class ParticipantsSectionHeader extends StatelessWidget {
  const ParticipantsSectionHeader({
    super.key,
    required this.label,
    required this.count,
    this.isInactive = false,
  });

  final String label;
  final int count;
  final bool isInactive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInactive ? AppColors.tabInactive : AppColors.success,
            ),
          ),
          AppSpacing.hGapSm,
          Text(
            '$label ($count)',
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
