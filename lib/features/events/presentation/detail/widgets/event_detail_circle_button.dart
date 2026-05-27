import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventDetailCircleButton extends StatelessWidget {
  const EventDetailCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkBgPrimary.withValues(alpha: 0.6), // #0D0D0F with 60% opacity
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.textOnDarkPrimary, size: 20),
      ),
    );
  }
}
