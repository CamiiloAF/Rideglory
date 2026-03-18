import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenanceAlertCard extends StatelessWidget {
  const MaintenanceAlertCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isOn,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOn ? context.colorScheme.primary : context.colorScheme.outlineVariant,
          width: isOn ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              Switch(
                value: isOn,
                onChanged: null,
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            label,
            style: context.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            value,
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            subtitle,
            style: context.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
