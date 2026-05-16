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

enum MaintenanceItemStatus { overdue, upcoming, current }

MaintenanceItemStatus maintenanceStatusOf(MaintenanceModel m) {
  final now = DateTime.now();
  if (m.nextMaintenanceDate != null && m.nextMaintenanceDate!.isBefore(now)) {
    return MaintenanceItemStatus.overdue;
  }
  if (m.nextMaintenanceDate != null &&
      m.nextMaintenanceDate!.difference(now).inDays <= 30) {
    return MaintenanceItemStatus.upcoming;
  }
  return MaintenanceItemStatus.current;
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

  static const _successColor = Color(0xFF22C55E);
  static const _warningColor = Color(0xFFEAB308);

  Color get _statusColor => switch (status) {
    MaintenanceItemStatus.overdue => AppColors.error,
    MaintenanceItemStatus.upcoming => _warningColor,
    MaintenanceItemStatus.current => _successColor,
  };

  Color get _cardBackground => switch (status) {
    MaintenanceItemStatus.overdue => const Color(0xFF1A0A0A),
    MaintenanceItemStatus.upcoming => const Color(0xFF1A1600),
    MaintenanceItemStatus.current => AppColors.darkCard,
  };

  Color get _cardBorder => switch (status) {
    MaintenanceItemStatus.overdue => const Color(0x30EF4444),
    MaintenanceItemStatus.upcoming => const Color(0x30EAB308),
    MaintenanceItemStatus.current => AppColors.darkBorderPrimary,
  };

  Color get _iconBackground => switch (status) {
    MaintenanceItemStatus.overdue => const Color(0x20EF4444),
    MaintenanceItemStatus.upcoming => const Color(0x20EAB308),
    MaintenanceItemStatus.current => MaintenanceTypeStyle.color(
      maintenance.type,
    ).withValues(alpha: 0.12),
  };

  Color get _iconColor => switch (status) {
    MaintenanceItemStatus.overdue => AppColors.error,
    MaintenanceItemStatus.upcoming => _warningColor,
    MaintenanceItemStatus.current => MaintenanceTypeStyle.color(
      maintenance.type,
    ),
  };

  int? _remainingKm(int? currentMileage) {
    final next = maintenance.nextMaintenanceMileage;
    if (next == null || currentMileage == null) return null;
    final remaining = next - currentMileage;
    return remaining > 0 ? remaining : 0;
  }

  String _subtitle(BuildContext context, int? currentMileage) {
    final numberFormat = NumberFormat('#,###');
    if (maintenance.nextMaintenanceMileage != null) {
      final remaining = _remainingKm(currentMileage);
      final km = numberFormat.format(
        remaining ?? maintenance.nextMaintenanceMileage,
      );
      if (status == MaintenanceItemStatus.overdue) return 'Venció en $km km';
      return 'Próximo en $km km';
    }
    if (maintenance.nextMaintenanceDate != null) {
      if (status == MaintenanceItemStatus.overdue) {
        return 'Venció el ${maintenance.nextMaintenanceDate!.formattedDate}';
      }
      return 'Próximo el ${maintenance.nextMaintenanceDate!.formattedDate}';
    }
    return maintenance.type.label;
  }

  Widget _kmBadge(BuildContext context, int? currentMileage) {
    final numberFormat = NumberFormat('#,###');
    if (maintenance.nextMaintenanceMileage != null) {
      final remaining = _remainingKm(currentMileage);
      final km = numberFormat.format(
        remaining ?? maintenance.nextMaintenanceMileage,
      );
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

  int? _currentMileageFor(VehicleCubit cubit) {
    final vehicleId = maintenance.vehicleId;
    if (vehicleId == null) return cubit.currentMileage;
    try {
      return cubit.availableVehicles
          .firstWhere((v) => v.id == vehicleId)
          .currentMileage;
    } catch (_) {
      return cubit.currentMileage;
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
                _kmBadge(context, currentMileage),
              ],
            ),
          ),
        );
      },
    );
  }
}
