import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/item_card/maintenance_card_content.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

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

  Color get _typeColor => switch (maintenance.type) {
    MaintenanceType.oilChange => AppColors.primary,
    MaintenanceType.brakeCheck => AppColors.statusWarning,
    MaintenanceType.tireChange => AppColors.info,
    MaintenanceType.preventive => AppColors.statusGreen,
    MaintenanceType.airFilter => AppColors.eventShortDistance,
    MaintenanceType.chainSprocket => AppColors.textOnDarkTertiary,
    MaintenanceType.electrical => AppColors.warningLight,
    MaintenanceType.other => AppColors.darkTertiary,
  };

  IconData get _typeIcon => switch (maintenance.type) {
    MaintenanceType.oilChange => Icons.opacity,
    MaintenanceType.brakeCheck => Icons.album_outlined,
    MaintenanceType.tireChange => Icons.radio_button_unchecked,
    MaintenanceType.preventive => Icons.assignment_turned_in_outlined,
    MaintenanceType.airFilter => Icons.air,
    MaintenanceType.chainSprocket => Icons.link,
    MaintenanceType.electrical => Icons.bolt,
    MaintenanceType.other => Icons.more_horiz,
  };

  double? _getProgressPercent(int? currentMileage) {
    final nextMileage = maintenance.nextOdometer;
    final atService = maintenance.odometerAtService;
    if (nextMileage == null || currentMileage == null || atService == null)
      return null;
    final range = nextMileage - atService;
    if (range <= 0) return 1.0;
    final traveled = currentMileage - atService;
    return (traveled / range).clamp(0.0, 1.0);
  }

  int? _getRemainingDistance(int? currentMileage) {
    final nextMileage = maintenance.nextOdometer;
    if (currentMileage == null || nextMileage == null) return null;
    final remaining = nextMileage - currentMileage;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
      builder: (context, _) {
        final availableVehicles = context
            .read<VehicleCubit>()
            .availableVehicles;
        VehicleModel? maintenanceVehicle;
        int? currentMileage;
        if (maintenance.vehicleId != null) {
          try {
            final matchedVehicle = availableVehicles.firstWhere(
              (vehicle) => vehicle.id == maintenance.vehicleId,
            );
            maintenanceVehicle = matchedVehicle;
            currentMileage = matchedVehicle.currentMileage;
          } catch (_) {
            maintenanceVehicle = null;
          }
        }

        final daysUntilNext = maintenance.nextDate
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
  }
}
