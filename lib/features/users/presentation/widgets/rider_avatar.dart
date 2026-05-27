import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class RiderAvatar extends StatelessWidget {
  const RiderAvatar({super.key, required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.4), // Intentional: gradient stop — alpha variant of primary
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkCard,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDarkPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
