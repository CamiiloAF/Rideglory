import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailNavButton extends StatelessWidget {
  const VehicleDetailNavButton({
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
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.darkBgSecondary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textOnDarkPrimary),
      ),
    );
  }
}
