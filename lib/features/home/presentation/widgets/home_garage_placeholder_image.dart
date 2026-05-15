import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Fallback placeholder shown when the garage card has no vehicle image.
class HomeGaragePlaceholderImage extends StatelessWidget {
  const HomeGaragePlaceholderImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(
          Icons.two_wheeler,
          size: 56,
          color: AppColors.darkBorderLight,
        ),
      ),
    );
  }
}
