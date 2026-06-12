import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// A single label/value row inside a [ReviewCard].
class ReviewRow extends StatelessWidget {
  const ReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.trailingWidget,
    this.isTitle = false,
    this.isSubtitle = false,
  });

  final String label;
  final String value;
  final Widget? trailingWidget;
  final bool isTitle;
  final bool isSubtitle;

  @override
  Widget build(BuildContext context) {
    if (isTitle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          value,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
      );
    }

    if (isSubtitle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 12,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      );
    }

    if (label.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          value,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 13,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 12,
              color: AppColors.textOnDarkTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (trailingWidget != null) ...[
                  trailingWidget!,
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnDarkPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
