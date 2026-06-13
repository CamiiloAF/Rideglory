import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Step title header block shown at the top of each wizard step's scroll content.
///
/// Design spec (Pencil AybHb / EzQtb / XbcHD / FW3Hd — stepTitle):
/// - Title: 22px w700 white
/// - Subtitle: 14px normal #9CA3AF
/// - Gap: 4px between title and subtitle
/// - Bottom padding in parent: 8px (managed by stepTitle frame)
class StepTitle extends StatelessWidget {
  const StepTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}
