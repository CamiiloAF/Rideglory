import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Limit banner shown when 9/9 waypoints are reached.
///
/// Design spec (Pencil kY0VR):
/// - Full-width, no border-radius, no lateral margin
/// - Fill: #2D2117, stroke: #F98C1F 1px inner, padding [10,16]
/// - Icon: info (lucide) in orange 16px
/// - Text: 12px w500, orange, line-height 1.4
class WaypointLimitBanner extends StatelessWidget {
  const WaypointLimitBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
