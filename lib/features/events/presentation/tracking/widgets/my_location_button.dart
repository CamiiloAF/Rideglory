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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled ? AppColors.primary : AppColors.darkBorderPrimary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Icon(
          Icons.my_location,
          size: 18,
          color: isEnabled ? AppColors.primary : AppColors.tabInactive,
        ),
      ),
    );
  }
}
