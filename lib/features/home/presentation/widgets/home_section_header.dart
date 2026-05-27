import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.viewAllLabel,
  });

  final String title;
  final VoidCallback onViewAll;
  final String viewAllLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            viewAllLabel.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
