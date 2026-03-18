import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

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
    final cs = context.colorScheme;
    final isOverlay = variant == DetailPillVariant.overlay;

    final backgroundColor = isOverlay
        ? cs.background.withOpacity(0.4)
        : cs.primary.withOpacity(0.25);

    final border = isOverlay
        ? Border.all(
            color: cs.onSurface.withOpacity(0.2),
            width: 1,
          )
        : null;

    final labelColor = isOverlay
        ? cs.onSurface.withOpacity(0.95)
        : cs.primary;

    final subtitleColor = isOverlay
        ? cs.onSurface.withOpacity(0.85)
        : cs.onSurfaceVariant;

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
                            ? cs.onSurface.withOpacity(0.98)
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
