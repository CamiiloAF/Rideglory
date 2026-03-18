import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.my_location,
            color: isEnabled ? AppColors.primary : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }
}
