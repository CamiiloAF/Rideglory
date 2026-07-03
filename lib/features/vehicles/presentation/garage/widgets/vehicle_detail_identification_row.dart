import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailIdentificationRow extends StatelessWidget {
  const VehicleDetailIdentificationRow({
    super.key,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
    this.trailing,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
