import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class WaypointCounter extends StatelessWidget {
  const WaypointCounter({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2D2117)
            : AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.l10n.route_builder_counter(count),
        style: TextStyle(
          color: isActive ? AppColors.primary : AppColors.textOnDarkTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
