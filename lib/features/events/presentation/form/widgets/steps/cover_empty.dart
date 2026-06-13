import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Empty cover placeholder — tapping opens the cover picker.
class CoverEmpty extends StatelessWidget {
  const CoverEmpty({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.darkBorderPrimary,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: AppColors.textOnDarkTertiary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.event_addEventCover,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.event_addEventCoverHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 11,
                color: AppColors.textOnDarkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
