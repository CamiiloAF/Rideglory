import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEventCardImagePlaceholder extends StatelessWidget {
  const HomeEventCardImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(Icons.route, size: 40, color: AppColors.darkBorderLight),
      ),
    );
  }
}
