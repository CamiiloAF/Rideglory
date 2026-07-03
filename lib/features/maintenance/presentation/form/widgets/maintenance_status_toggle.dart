import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenanceStatusToggle extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  const MaintenanceStatusToggle({
    super.key,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.statusGreen
                      : Colors
                            .transparent, // Intentional: toggle background resets to transparent when inactive
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    context.l10n.maintenance_form_tab_done,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.textOnDarkPrimary
                          : AppColors.textOnDarkSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: !isCompleted
                      ? AppColors.primary
                      : Colors
                            .transparent, // Intentional: toggle background resets to transparent when inactive
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    context.l10n.maintenance_form_tab_scheduled,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !isCompleted
                          ? AppColors.textOnDarkPrimary
                          : AppColors.textOnDarkSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
