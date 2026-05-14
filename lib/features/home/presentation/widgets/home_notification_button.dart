import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeNotificationButton extends StatelessWidget {
  const HomeNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.darkTertiary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.notifications,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}
