import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleFormSectionHeader extends StatelessWidget {
  const VehicleFormSectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.trailing,
  });

  final String title;
  final Widget? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDarkTertiary,
            letterSpacing: 1.2,
          ),
        ),
        if (badge != null) ...[const SizedBox(width: 8), badge!],
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}
