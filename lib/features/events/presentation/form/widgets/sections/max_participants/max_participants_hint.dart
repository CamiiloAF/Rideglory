import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaxParticipantsHint extends StatelessWidget {
  const MaxParticipantsHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.group_outlined,
          size: 13,
          color: AppColors.textOnDarkTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.l10n.event_form_max_participants_hint,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: AppColors.textOnDarkTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
