import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class FilterTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterTypeChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : const Border.fromBorderSide(
                  BorderSide(color: AppColors.darkBorderPrimary),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.darkBgPrimary : AppColors.textOnDarkSecondary,
          ),
        ),
      ),
    );
  }
}
