import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class FilterRadioIndicator extends StatelessWidget {
  final bool isSelected;

  const FilterRadioIndicator({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.textOnDarkPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.darkBorderPrimary, width: 1.5),
      ),
    );
  }
}
