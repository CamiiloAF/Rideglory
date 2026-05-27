import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailImagePlaceholder extends StatelessWidget {
  const VehicleDetailImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(Icons.two_wheeler, size: 64, color: AppColors.darkBorderLight),
      ),
    );
  }
}
