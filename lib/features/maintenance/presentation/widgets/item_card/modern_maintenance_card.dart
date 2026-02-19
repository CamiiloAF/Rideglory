import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_card_content.dart';

class ModernMaintenanceCard extends StatelessWidget {
  final MaintenanceModel maintenance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ModernMaintenanceCard({
    super.key,
    required this.maintenance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color get _typeColor {
    return maintenance.type == MaintenanceType.oilChange
        ? const Color(0xFF6366F1)
        : const Color(0xFF8B5CF6);
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

  int? _getRemainingDistance(int? currentMileage) {
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

        return BlocBuilder<VehicleListCubit, ResultState<List<VehicleModel>>>(
          builder: (context, vehicleListState) {
            VehicleModel? maintenanceVehicle;
            if (maintenance.vehicleId != null &&
                vehicleListState is Data<List<VehicleModel>>) {
              try {
                maintenanceVehicle = vehicleListState.data.firstWhere(
                  (v) => v.id == maintenance.vehicleId,
                );
              } catch (e) {
                // Vehicle not found
              }
            }

            final daysUntilNext = maintenance.nextMaintenanceDate
                ?.difference(DateTime.now())
                .inDays;

            final progressPercent = _getProgressPercent(currentMileage);
            final isUrgent =
                (daysUntilNext != null && daysUntilNext < 10) ||
                (progressPercent != null && progressPercent >= 0.95);

            return MaintenanceCardContent(
              maintenance: maintenance,
              maintenanceVehicle: maintenanceVehicle,
              typeColor: _typeColor,
              typeIcon: _typeIcon,
              currentMileage: currentMileage,
              progressPercent: progressPercent,
              isUrgent: isUrgent,
              daysUntilNext: daysUntilNext,
              getRemainingDistance: _getRemainingDistance,
              onTap: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
            );
          },
        );
      },
    );
  }
}
