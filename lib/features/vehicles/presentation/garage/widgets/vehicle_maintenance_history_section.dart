import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleMaintenanceHistorySection extends StatelessWidget {
  const VehicleMaintenanceHistorySection({
    super.key,
    required this.vehicle,
    required this.maintenanceRefreshTick,
    this.pendingCreatedMaintenance,
    this.onPendingMaintenanceConsumed,
    this.isArchived = false,
  });

  final VehicleModel vehicle;
  final int maintenanceRefreshTick;
  final MaintenanceModel? pendingCreatedMaintenance;
  final void Function(String vehicleId)? onPendingMaintenanceConsumed;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('${vehicle.id}-$maintenanceRefreshTick'),
      create: (context) =>
          getIt<VehicleMaintenancesCubit>()..fetchMaintenances(vehicle.id!),
      child: Builder(
        builder: (sectionContext) {
          final createdMaintenance = pendingCreatedMaintenance;
          if (createdMaintenance != null &&
              createdMaintenance.vehicleId == vehicle.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!sectionContext.mounted) return;
              sectionContext
                  .read<VehicleMaintenancesCubit>()
                  .addMaintenanceLocally(
                    createdMaintenance,
                    vehicleId: vehicle.id!,
                  );
              onPendingMaintenanceConsumed?.call(vehicle.id!);
            });
          }

          return BlocBuilder<VehicleMaintenancesCubit,
              ResultState<List<MaintenanceModel>>>(
            builder: (context, _) {
              final cubit = context.read<VehicleMaintenancesCubit>();
              return _MaintenanceCards(
                lastCompleted: cubit.lastCompleted,
                nextScheduled: cubit.nextScheduled,
                vehicleId: vehicle.id,
                currentMileage: vehicle.currentMileage,
                isArchived: isArchived,
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Two-card summary + CTA button ──────────────────────────────────────────

class _MaintenanceCards extends StatelessWidget {
  const _MaintenanceCards({
    this.lastCompleted,
    this.nextScheduled,
    this.vehicleId,
    required this.currentMileage,
    this.isArchived = false,
  });

  final MaintenanceModel? lastCompleted;
  final MaintenanceModel? nextScheduled;
  final String? vehicleId;
  final int currentMileage;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ServiceCard.last(
                  maintenance: lastCompleted,
                  maintenanceId: lastCompleted?.id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ServiceCard.next(
                  maintenance: nextScheduled,
                  maintenanceId: nextScheduled?.id,
                  currentMileage: currentMileage,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HistoryButton(vehicleId: vehicleId, isArchived: isArchived),
      ],
    );
  }
}

// ─── Service summary card ────────────────────────────────────────────────────

enum _CardType { last, next }

class _ServiceCard extends StatelessWidget {
  const _ServiceCard.last({this.maintenance, this.maintenanceId})
    : _type = _CardType.last,
      _currentMileage = 0;
  const _ServiceCard.next({
    this.maintenance,
    this.maintenanceId,
    required int currentMileage,
  }) : _type = _CardType.next,
       _currentMileage = currentMileage;

  final MaintenanceModel? maintenance;
  final String? maintenanceId;
  final _CardType _type;
  final int _currentMileage;

  bool get _isLast => _type == _CardType.last;

  bool get _isOverdue {
    if (_isLast || maintenance == null) return false;
    return MaintenanceModel.calculateStatus(maintenance!, _currentMileage) ==
        MaintenanceStatus.overdue;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('d MMM. yyyy', 'es').format(date);
  }

  String _formatKm(int? km) {
    if (km == null) return '—';
    return '${NumberFormat('#,###').format(km).replaceAll(',', '.')} km';
  }

  String _primaryValue() {
    if (_isLast) {
      final date = maintenance?.serviceDate;
      final km = maintenance?.odometerAtService;
      if (date != null) return _formatDate(date);
      if (km != null) return _formatKm(km);
      return '—';
    } else {
      final km = maintenance?.nextOdometer;
      final date = maintenance?.nextDate;
      if (km != null) return _formatKm(km);
      if (date != null) return _formatDate(date);
      return '—';
    }
  }

  String? _secondaryValue() {
    if (_isLast) {
      final date = maintenance?.serviceDate;
      final km = maintenance?.odometerAtService;
      if (date != null && km != null) return _formatKm(km);
      return null;
    } else {
      final km = maintenance?.nextOdometer;
      final date = maintenance?.nextDate;
      if (km != null && date != null) return _formatDate(date);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _isOverdue;
    final iconColor = _isLast
        ? AppColors.info
        : overdue
            ? AppColors.error
            : AppColors.primary;
    final badgeText = _isLast
        ? context.l10n.maintenance_done
        : overdue
            ? context.l10n.maintenance_statusOverdue
            : context.l10n.maintenance_legend_warning;
    final bgColor = overdue ? AppColors.statusError.withValues(alpha: 0.1) : AppColors.darkCard;
    final borderColor =
        overdue ? AppColors.statusError.withValues(alpha: 0.25) : AppColors.darkBorderPrimary;
    final primary = _primaryValue();
    final secondary = _secondaryValue();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                _isLast ? Icons.calendar_today : Icons.calendar_month_outlined,
                size: 16,
                color: iconColor,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            primary,
            style: TextStyle(
              color: overdue
                  ? AppColors.error
                  : AppColors.textOnDarkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 4),
            Text(
              secondary,
              style: TextStyle(
                color: overdue
                    ? AppColors.error.withValues(alpha: 0.7)
                    : AppColors.textOnDarkSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── History CTA button ──────────────────────────────────────────────────────

class _HistoryButton extends StatelessWidget {
  const _HistoryButton({this.vehicleId, this.isArchived = false});

  final String? vehicleId;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        AppRoutes.maintenances,
        extra: isArchived
            ? <String, dynamic>{'vehicleId': vehicleId, 'readOnly': true}
            : vehicleId,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.maintenance_viewHistory,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
