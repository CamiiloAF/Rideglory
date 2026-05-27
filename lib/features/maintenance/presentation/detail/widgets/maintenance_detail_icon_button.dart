import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenanceDetailIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const MaintenanceDetailIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: AppColors.textOnDarkPrimary, size: 18),
      ),
    );
  }
}
