import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class TelemetryMetric extends StatelessWidget {
  const TelemetryMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor =
        valueColor ?? AppColors.textOnDarkPrimary;

    return Expanded(
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: resolvedValueColor,
                ),
                AppSpacing.hGapXxs,
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: resolvedValueColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
