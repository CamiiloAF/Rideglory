import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class ParticipantsEmptyState extends StatelessWidget {
  const ParticipantsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkTertiary,
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: AppColors.textOnDarkTertiary,
                size: 32,
              ),
            ),
            AppSpacing.gapXl,
            Text(
              context.l10n.map_noActiveRidersMessage,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
