import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenancesAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final bool hasBorder;
  final bool isAccent;
  final VoidCallback onTap;

  const MaintenancesAppBarIconButton({
    super.key,
    required this.icon,
    required this.hasBorder,
    this.isAccent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isAccent ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: hasBorder
              ? Border.all(color: AppColors.darkBorderPrimary)
              : null,
        ),
        child: Icon(
          icon,
          color: isAccent
              ? colorScheme.onPrimary
              : AppColors.textOnDarkPrimary,
          size: 16,
        ),
      ),
    );
  }
}
