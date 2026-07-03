import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class HomeEventGradientOverlay extends StatelessWidget {
  const HomeEventGradientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors
                .transparent, // Intentional: gradient stop — transparent start
            AppColors.darkBgPrimary.withValues(alpha: 0.87),
          ],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }
}
