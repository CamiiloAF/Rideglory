import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class WaypointsEmptyHint extends StatelessWidget {
  const WaypointsEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.route,
            color: AppColors.textOnDarkTertiary,
            size: 28,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: Text(
              context.l10n.route_builder_empty_hint,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                color: AppColors.textOnDarkTertiary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
