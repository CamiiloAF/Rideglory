import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class SplashGlowBackground extends StatelessWidget {
  const SplashGlowBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 340,
          height: 340,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                context.colorScheme.primary.withValues(alpha: 0.22),
                AppColors.darkBackground.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
