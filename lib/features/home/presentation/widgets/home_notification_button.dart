import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class HomeNotificationButton extends StatelessWidget {
  const HomeNotificationButton({super.key, required this.showBadge});

  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.darkTextPrimary,
            size: 22,
          ),
        ),
        if (showBadge)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
