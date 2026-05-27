import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailCardHeader extends StatelessWidget {
  const VehicleDetailCardHeader({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textOnDarkTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
