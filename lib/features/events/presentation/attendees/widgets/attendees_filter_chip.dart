import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Chip individual del filtro de estado en "Gestionar Inscritos".
class AttendeesFilterChip extends StatelessWidget {
  const AttendeesFilterChip({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.darkBorderPrimary,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.darkBgPrimary
                  : AppColors.textOnDarkSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
