import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class SplashBrandContent extends StatelessWidget {
  const SplashBrandContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.appName.toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect. Ride. Explore.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textOnDarkSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
