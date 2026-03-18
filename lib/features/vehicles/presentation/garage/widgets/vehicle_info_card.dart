import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleInfoCard extends StatelessWidget {
  const VehicleInfoCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C241E), // Brownish dark similar to mockup
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.colorScheme.primary, size: 18),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: context.labelSmall?.copyWith(
                    color: context.colorScheme.primary,
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
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
