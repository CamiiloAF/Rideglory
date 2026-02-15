import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class InfoChipTooltip extends StatelessWidget {
  const InfoChipTooltip({
    super.key,
    required this.typeColor,
    required this.currentMileage,
    required this.maintenance,
  });

  final Color typeColor;
  final int? currentMileage;
  final MaintenanceModel maintenance;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ver kilometraje actual del vehículo',
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierColor: Colors.black.withValues(alpha: .4),
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.all(20),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withValues(alpha: .1),
                            typeColor.withValues(alpha: .05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.speed_rounded,
                        size: 32,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kilometraje Actual',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentMileage?.toStringAsFixed(0) ?? '-'} ${maintenance.distanceUnit.label}',
                        style: TextStyle(
                          fontSize: 24,
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: .1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: typeColor.withValues(alpha: .2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.info_rounded, color: typeColor, size: 16),
          ),
        ),
      ),
    );
  }
}
