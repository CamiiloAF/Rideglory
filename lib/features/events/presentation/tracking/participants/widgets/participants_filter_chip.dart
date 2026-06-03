import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Chip individual del filtro de participantes en el panel de tracking en vivo.
class ParticipantsFilterChip extends StatelessWidget {
  const ParticipantsFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// When non-null, a small colored dot is shown before the label.
  final Color? dotColor;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.darkBgPrimary : dotColor,
                  ),
                ),
                AppSpacing.hGapXxs,
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.darkBgPrimary
                      : AppColors.textOnDarkSecondary,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
