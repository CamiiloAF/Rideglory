import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class HomeVehiclePlaceholderImage extends StatelessWidget {
  const HomeVehiclePlaceholderImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: AppColors.darkSurfaceHighest,
      child: const Icon(
        Icons.two_wheeler,
        size: 64,
        color: AppColors.darkBorder,
      ),
    );
  }
}
