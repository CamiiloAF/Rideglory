import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Generic empty-state widget for vehicle document pages.
///
/// Shows an icon, title, subtitle and a single CTA button.
class DocumentEmptyState extends StatelessWidget {
  const DocumentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onCta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: Icon(icon, color: AppColors.textOnDarkTertiary, size: 40),
            ),
            AppSpacing.gapXxl,
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            AppSpacing.gapXxl,
            AppButton(label: ctaLabel, onPressed: onCta),
          ],
        ),
      ),
    );
  }
}
