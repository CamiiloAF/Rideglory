import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';

class HomeEmptyGarageCard extends StatelessWidget {
  const HomeEmptyGarageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.two_wheeler, size: 48, color: AppColors.darkBorder),
          SizedBox(height: 8),
          Text(
            HomeStrings.emptyGarage,
            style: TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            HomeStrings.emptyGarageDescription,
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
