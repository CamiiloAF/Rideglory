import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class EventTypeChip extends StatelessWidget {
  const EventTypeChip({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final EventType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(17),
          border: isSelected
              ? null
              : Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Center(
          child: Text(
            type.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.darkBgPrimary
                  : AppColors.textOnDarkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
