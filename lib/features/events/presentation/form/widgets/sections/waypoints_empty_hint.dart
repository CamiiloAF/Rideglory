import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class WaypointsEmptyHint extends StatelessWidget {
  const WaypointsEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(
            Icons.navigation,
            color: AppColors.textOnDarkTertiary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.route_builder_empty_hint,
            style: const TextStyle(
              fontFamily: 'Space Grotesk',
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
