import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
        color: isActive ? AppColors.primarySubtle : AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.mapPin,
            size: 12,
            color: isActive ? AppColors.primary : AppColors.textOnDarkTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.route_builder_counter(count),
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              color: isActive ? AppColors.primary : AppColors.textOnDarkTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
