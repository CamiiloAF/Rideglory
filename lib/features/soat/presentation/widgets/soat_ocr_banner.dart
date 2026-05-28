import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Subtle banner shown atop the manual form when fields were prefilled from
/// OCR. When [needsCarefulReview] is true the copy nudges the user to
/// double-check medium-confidence fields.
class SoatOcrBanner extends StatelessWidget {
  const SoatOcrBanner({super.key, this.needsCarefulReview = false});

  final bool needsCarefulReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_fix_high_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              needsCarefulReview
                  ? context.l10n.soat_scan_banner_review
                  : context.l10n.soat_scan_banner,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
