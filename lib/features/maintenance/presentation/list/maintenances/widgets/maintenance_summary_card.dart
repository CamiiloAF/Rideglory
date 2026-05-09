import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenanceSummaryCard extends StatelessWidget {
  const MaintenanceSummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 18),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: context.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Text(
            value,
            style: context.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            AppSpacing.gapXxs,
            Text(
              subtitle!,
              style: context.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
