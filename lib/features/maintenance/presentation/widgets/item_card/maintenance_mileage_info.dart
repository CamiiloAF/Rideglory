import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/info_chip.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_progress_bar.dart';

/// Widget para mostrar la información de kilometraje del mantenimiento
class MaintenanceMileageInfo extends StatelessWidget {
  final MaintenanceModel maintenance;
  final Color typeColor;
  final double? currentMileage;
  final double? progressPercent;
  final double? Function(double?) getRemainingDistance;

  const MaintenanceMileageInfo({
    super.key,
    required this.maintenance,
    required this.typeColor,
    required this.currentMileage,
    required this.progressPercent,
    required this.getRemainingDistance,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDistance = getRemainingDistance(currentMileage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: .1), width: 1),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InfoChip(
                    icon: Icons.build_rounded,
                    label: 'Mantenimiento',
                    value:
                        '${maintenance.maintanceMileage.toStringAsFixed(0)} ${maintenance.distanceUnit.label}',
                    color: const Color(0xFF64748B),
                  ),
                  if (maintenance.nextMaintenanceMileage != null)
                    InfoChip(
                      icon: Icons.flag_rounded,
                      label: 'Próximo',
                      value:
                          '${maintenance.nextMaintenanceMileage!.toStringAsFixed(0)} ${maintenance.distanceUnit.label}',
                      color: typeColor,
                    ),
                ],
              ),
              if (progressPercent != null) ...[
                const SizedBox(height: 12),
                MaintenanceProgressBar(
                  typeColor: typeColor,
                  progressPercent: progressPercent!,
                ),
                const SizedBox(height: 8),
                Text(
                  remainingDistance != null
                      ? '${remainingDistance.toStringAsFixed(0)} ${maintenance.distanceUnit.label} restantes'
                      : 'Calcular distancia restante',
                  style: TextStyle(
                    fontSize: 12,
                    color: remainingDistance != null && remainingDistance <= 0
                        ? const Color(0xFFEF4444)
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          // Info icon positioned absolutely in top-right corner
          Positioned(
            top: 0,
            right: 0,
            child: Tooltip(
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
            ),
          ),
        ],
      ),
    );
  }
}
