import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Filter chip for the events list screen.
/// Matches Pencil design: h=34, radius=17, padding=[0,16]
/// Active: fill=#F98C1F, text 13/600 #0D0D0F
/// Inactive: fill=#242429, text 13/500 #9CA3AF
class EventFilterChip extends StatelessWidget {
  const EventFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(17),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.darkBgPrimary
                : AppColors.textOnDarkSecondary,
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w500,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
