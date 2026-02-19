import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? value;
  final Widget? tooltip;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.value,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // Compact layout: horizontal chip for brief info (e.g., vehicle cards)
    if (value == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    // Detailed layout: vertical display with label and value (e.g., maintenance info)
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: context.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (tooltip != null) ...[const SizedBox(width: 4), tooltip!],
              ],
            ),
            Text(
              value!,
              style: context.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
