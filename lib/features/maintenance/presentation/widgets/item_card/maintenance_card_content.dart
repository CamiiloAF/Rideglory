import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_card_header.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_dates_section.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_mileage_info.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_notes_section.dart';

class MaintenanceCardContent extends StatelessWidget {
  final MaintenanceModel maintenance;
  final Color typeColor;
  final IconData typeIcon;
  final double? currentMileage;
  final double? progressPercent;
  final bool isUrgent;
  final int? daysUntilNext;
  final double? Function(double?) getRemainingDistance;

  const MaintenanceCardContent({
    super.key,
    required this.maintenance,
    required this.typeColor,
    required this.typeIcon,
    required this.currentMileage,
    required this.progressPercent,
    required this.isUrgent,
    required this.daysUntilNext,
    required this.getRemainingDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, typeColor.withValues(alpha: 0.05)],
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: .1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MaintenanceCardHeader(
                    maintenance: maintenance,
                    typeColor: typeColor,
                    typeIcon: typeIcon,
                    isUrgent: isUrgent,
                  ),
                  const SizedBox(height: 20),
                  MaintenanceMileageInfo(
                    maintenance: maintenance,
                    typeColor: typeColor,
                    currentMileage: currentMileage,
                    progressPercent: progressPercent,
                    getRemainingDistance: getRemainingDistance,
                  ),
                  const SizedBox(height: 16),
                  MaintenanceDatesSection(
                    maintenance: maintenance,
                    daysUntilNext: daysUntilNext,
                  ),
                  if (maintenance.notes != null &&
                      maintenance.notes!.isNotEmpty)
                    MaintenanceNotesSection(maintenance: maintenance),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
