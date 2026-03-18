import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleGarageOverviewItem extends StatelessWidget {
  const VehicleGarageOverviewItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E), // Darker gray card
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF3A3A3C),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colorScheme.primary, size: 20),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: context.labelSmall?.copyWith(
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                AppSpacing.gapXxs,
                Text(
                  value,
                  style: context.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
