import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaxParticipantsCardLabels extends StatelessWidget {
  const MaxParticipantsCardLabels({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_form_max_participants_label,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.event_form_max_participants_subtitle,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.normal,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
      ],
    );
  }
}
