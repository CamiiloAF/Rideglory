import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/item_card.dart';

class ModernMaintenanceCard extends StatelessWidget {
  final MaintenanceModel maintenance;

  const ModernMaintenanceCard({super.key, required this.maintenance});

  Color get _typeColor {
    return maintenance.type == MaintenanceType.oilChange
        ? const Color(0xFF6366F1) // Indigo
        : const Color(0xFF8B5CF6); // Purple
  }

  IconData get _typeIcon {
    return maintenance.type == MaintenanceType.oilChange
        ? Icons.oil_barrel_rounded
        : Icons.build_circle_rounded;
  }

  double? _getProgressPercent(int? currentMileage) {
    final nextMaintenanceMileage = maintenance.nextMaintenanceMileage;

    if (nextMaintenanceMileage == null || currentMileage == null) return null;

    final totalDistance = nextMaintenanceMileage - maintenance.maintanceMileage;

    if (totalDistance <= 0) return 1.0;

    return currentMileage / nextMaintenanceMileage;
  }

  double? _getRemainingDistance(int? currentMileage) {
    if (currentMileage == null || maintenance.nextMaintenanceMileage == null) {
      return null;
    }
    final remaining = maintenance.nextMaintenanceMileage! - currentMileage;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, vehicleState) {
        final currentMileage = vehicleState is VehicleLoaded
            ? vehicleState.vehicle.currentMileage
            : null;

        final daysUntilNext = maintenance.nextMaintenanceDate
            ?.difference(DateTime.now())
            .inDays;

        final progressPercent = _getProgressPercent(currentMileage);
        final isUrgent =
            (daysUntilNext != null && daysUntilNext < 10) ||
            (progressPercent != null && progressPercent >= 0.95);

        return _MaintenanceCardContent(
          maintenance: maintenance,
          typeColor: _typeColor,
          typeIcon: _typeIcon,
          currentMileage: currentMileage,
          progressPercent: progressPercent,
          isUrgent: isUrgent,
          daysUntilNext: daysUntilNext,
          getRemainingDistance: _getRemainingDistance,
        );
      },
    );
  }
}

class _MaintenanceCardContent extends StatelessWidget {
  final MaintenanceModel maintenance;
  final Color typeColor;
  final IconData typeIcon;
  final int? currentMileage;
  final double? progressPercent;
  final bool isUrgent;
  final int? daysUntilNext;
  final double? Function(int?) getRemainingDistance;

  const _MaintenanceCardContent({
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
