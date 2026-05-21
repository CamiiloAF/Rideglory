import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class WaypointsEmptyHint extends StatelessWidget {
  const WaypointsEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.darkBorderPrimary,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.route_outlined,
            color: AppColors.textOnDarkTertiary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.route_builder_empty_hint,
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
