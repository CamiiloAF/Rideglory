import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Titled card used in [EventFormStep4Review] for a review section.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
                const Spacer(),
                AppTextButton(
                  label: context.l10n.event_step_review_editButton,
                  onPressed: onEdit,
                  variant: AppTextButtonVariant.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}
