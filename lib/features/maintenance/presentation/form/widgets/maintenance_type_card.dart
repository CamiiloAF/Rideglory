import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/maintenance_type_style.dart';

class MaintenanceTypeCard extends StatelessWidget {
  final MaintenanceType type;
  final bool isSelected;
  final VoidCallback onTap;

  const MaintenanceTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = MaintenanceTypeStyle.color(type);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 104,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySubtle : AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                MaintenanceTypeStyle.icon(type),
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                type.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
