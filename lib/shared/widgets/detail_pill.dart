import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

enum DetailPillVariant {
  overlay,
  primary,
}

class DetailPill extends StatelessWidget {
  const DetailPill({
    super.key,
    required this.leading,
    required this.label,
    this.subtitle,
    this.variant = DetailPillVariant.overlay,
  });

  final Widget leading;
  final String label;
  final String? subtitle;
  final DetailPillVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverlay = variant == DetailPillVariant.overlay;

    final backgroundColor = isOverlay
        ? Colors.black.withValues(alpha: 0.4)
        : AppColors.primary.withValues(alpha: 0.25);

    final border = isOverlay
        ? Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          )
        : null;

    final labelColor = isOverlay
        ? Colors.white.withValues(alpha: 0.95)
        : theme.colorScheme.primary;

    final subtitleColor = isOverlay
        ? Colors.white.withValues(alpha: 0.85)
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          SizedBox(width: subtitle != null ? 8 : 6),
          subtitle != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: isOverlay
                            ? Colors.white.withValues(alpha: 0.98)
                            : labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ],
      ),
    );
  }
}
