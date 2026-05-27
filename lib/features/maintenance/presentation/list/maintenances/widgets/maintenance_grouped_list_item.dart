import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/maintenance_type_style.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

enum MaintenanceItemStatus { overdue, upcoming, current, completed }

/// Derives a [MaintenanceItemStatus] from the new [MaintenanceModel] fields
/// and the vehicle's current mileage for display purposes in the list widget.
MaintenanceItemStatus maintenanceStatusOf(
  MaintenanceModel maintenance,
  int currentVehicleMileage,
) {
  if (maintenance.mode == MaintenanceMode.completed) {
    return MaintenanceItemStatus.completed;
  }
  final status = MaintenanceModel.calculateStatus(
    maintenance,
    currentVehicleMileage,
  );
  switch (status) {
    case MaintenanceStatus.overdue:
      return MaintenanceItemStatus.overdue;
    case MaintenanceStatus.next:
      return MaintenanceItemStatus.upcoming;
    case MaintenanceStatus.upToDate:
    case null:
      return MaintenanceItemStatus.current;
  }
}

class MaintenanceGroupedListItem extends StatelessWidget {
  final MaintenanceModel maintenance;
  final MaintenanceItemStatus status;
  final VoidCallback onTap;

  const MaintenanceGroupedListItem({
    super.key,
    required this.maintenance,
    required this.status,
    required this.onTap,
  });

  static const _successColor = AppColors.statusGreen;
  static const _warningColor = AppColors.statusWarning;
  static const _completedColor = AppColors.textOnDarkTertiary;

  Color get _statusColor => switch (status) {
    MaintenanceItemStatus.overdue => AppColors.error,
    MaintenanceItemStatus.upcoming => _warningColor,
    MaintenanceItemStatus.current => _successColor,
    MaintenanceItemStatus.completed => _completedColor,
  };

  Color get _cardBackground => switch (status) {
    MaintenanceItemStatus.overdue => AppColors.errorSubtle,
    MaintenanceItemStatus.upcoming => AppColors.warningSubtle,
    MaintenanceItemStatus.current => AppColors.darkCard,
    MaintenanceItemStatus.completed => AppColors.darkCard,
  };

  Color get _cardBorder => switch (status) {
    MaintenanceItemStatus.overdue => AppColors.statusError.withValues(alpha: 0.19),
    MaintenanceItemStatus.upcoming => AppColors.statusWarning.withValues(alpha: 0.19),
    MaintenanceItemStatus.current => AppColors.darkBorderPrimary,
    MaintenanceItemStatus.completed => AppColors.darkBorderPrimary,
  };

  Color get _iconBackground => switch (status) {
    MaintenanceItemStatus.overdue => AppColors.statusError.withValues(alpha: 0.13),
    MaintenanceItemStatus.upcoming => AppColors.statusWarning.withValues(alpha: 0.13),
    MaintenanceItemStatus.current => MaintenanceTypeStyle.color(
      maintenance.type,
    ).withValues(alpha: 0.12),
    MaintenanceItemStatus.completed => MaintenanceTypeStyle.color(
      maintenance.type,
    ).withValues(alpha: 0.12),
  };

  Color get _iconColor => switch (status) {
    MaintenanceItemStatus.overdue => AppColors.error,
    MaintenanceItemStatus.upcoming => _warningColor,
    MaintenanceItemStatus.current => MaintenanceTypeStyle.color(
      maintenance.type,
    ),
    MaintenanceItemStatus.completed => MaintenanceTypeStyle.color(
      maintenance.type,
    ),
  };

  int? _kmDelta(int currentMileage) {
    final next = maintenance.nextOdometer;
    if (next == null) return null;
    return (next - currentMileage).abs();
  }

  String _subtitle(BuildContext context, int currentMileage) {
    final numberFormat = NumberFormat('#,###');
    if (maintenance.mode == MaintenanceMode.completed) {
      final date = maintenance.serviceDate;
      final km = maintenance.odometerAtService;
      if (date != null && km != null) {
        return 'Realizado el ${date.formattedDate} · ${numberFormat.format(km)} km';
      }
      if (date != null) return 'Realizado el ${date.formattedDate}';
      return maintenance.type.label;
    }

    if (maintenance.nextOdometer != null) {
      final delta = _kmDelta(currentMileage);
      final km = numberFormat.format(delta ?? maintenance.nextOdometer);
      if (status == MaintenanceItemStatus.overdue) return 'Atrasado por $km km';
      return 'Próximo en $km km';
    }
    if (maintenance.nextDate != null) {
      if (status == MaintenanceItemStatus.overdue) {
        return 'Venció el ${maintenance.nextDate!.formattedDate}';
      }
      return 'Próximo el ${maintenance.nextDate!.formattedDate}';
    }
    return maintenance.type.label;
  }

  Widget _rightBadge(BuildContext context, int currentMileage) {
    final numberFormat = NumberFormat('#,###');
    if (maintenance.mode == MaintenanceMode.completed) {
      return const SizedBox.shrink();
    }
    if (maintenance.nextOdometer != null) {
      final delta = _kmDelta(currentMileage);
      final km = numberFormat.format(delta ?? maintenance.nextOdometer);
      final label = status == MaintenanceItemStatus.overdue
          ? context.l10n.maintenance_expired_label
          : context.l10n.maintenance_km_remaining;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$km km',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  int _currentMileageFor(VehicleCubit cubit) {
    final vehicleId = maintenance.vehicleId;
    if (vehicleId == null) return cubit.currentMileage ?? 0;
    try {
      return cubit.availableVehicles
          .firstWhere((vehicle) => vehicle.id == vehicleId)
          .currentMileage;
    } catch (_) {
      return cubit.currentMileage ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
      builder: (context, _) {
        final currentMileage = _currentMileageFor(context.read<VehicleCubit>());
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _iconBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    MaintenanceTypeStyle.icon(maintenance.type),
                    color: _iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maintenance.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textOnDarkPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(context, currentMileage),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDarkTertiary,
                          fontWeight: FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _rightBadge(context, currentMileage),
              ],
            ),
          ),
        );
      },
    );
  }
}
