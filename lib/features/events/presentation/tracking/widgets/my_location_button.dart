import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

class MyLocationButton extends StatelessWidget {
  const MyLocationButton({
    super.key,
    required this.onTap,
    required this.isEnabled,
  });

  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? AppColors.primary.withValues(alpha: 0.6) : AppColors.darkBorderPrimary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Icon(
          Icons.my_location_rounded,
          size: 20,
          color: isEnabled ? AppColors.primary : AppColors.tabInactive,
        ),
      ),
    );
  }
}
