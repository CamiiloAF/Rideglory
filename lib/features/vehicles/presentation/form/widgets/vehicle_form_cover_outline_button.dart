import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleFormCoverOutlineButton extends StatelessWidget {
  const VehicleFormCoverOutlineButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textOnDarkSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
