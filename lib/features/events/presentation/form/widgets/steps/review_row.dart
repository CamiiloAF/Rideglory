import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// A single label/value row inside a [ReviewCard].
///
/// Design spec (Pencil FW3Hd):
/// - Padding: [11, 16] (vertical 11, horizontal 16)
/// - Label: 13px normal, color #9CA3AF
/// - Value: 13px w600, color #FFFFFF
/// - Layout: space_between with optional trailingWidget before value
class ReviewRow extends StatelessWidget {
  const ReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.trailingWidget,
    this.isTitle = false,
    this.isSubtitle = false,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Widget? trailingWidget;
  final bool isTitle;
  final bool isSubtitle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isTitle) {
      content = Text(
        value,
        style: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnDarkPrimary,
        ),
      );
    } else if (isSubtitle) {
      content = Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 13,
          color: AppColors.textOnDarkSecondary,
        ),
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 13,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDarkPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: content,
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
      ],
    );
  }
}
