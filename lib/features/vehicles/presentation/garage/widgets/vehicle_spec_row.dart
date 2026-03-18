import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleSpecRow extends StatelessWidget {
  const VehicleSpecRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C241E), // Dark brown matches mockup
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.colorScheme.primary, size: 20),
          AppSpacing.hGapLg,
          Text(label, style: context.bodyMedium?.copyWith(color: Colors.white)),
          Spacer(),
          Text(
            value,
            style: context.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
