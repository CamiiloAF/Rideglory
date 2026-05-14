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
  });

  final VehicleModel vehicle;
  final int maintenanceRefreshTick;
  final MaintenanceModel? pendingCreatedMaintenance;
  final void Function(String vehicleId)? onPendingMaintenanceConsumed;

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
            builder: (context, state) {
              final latest = state.maybeWhen(
                data: (list) => list.isNotEmpty ? list.first : null,
                orElse: () => null,
              );
              return _MaintenanceCards(
                latest: latest,
                vehicleId: vehicle.id,
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
  const _MaintenanceCards({this.latest, this.vehicleId});

  final MaintenanceModel? latest;
  final String? vehicleId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _ServiceCard.last(maintenance: latest)),
            const SizedBox(width: 12),
            Expanded(child: _ServiceCard.next(maintenance: latest)),
          ],
        ),
        const SizedBox(height: 12),
        _HistoryButton(vehicleId: vehicleId),
      ],
    );
  }
}

// ─── Service summary card ────────────────────────────────────────────────────

enum _CardType { last, next }

class _ServiceCard extends StatelessWidget {
  const _ServiceCard.last({this.maintenance}) : _type = _CardType.last;
  const _ServiceCard.next({this.maintenance}) : _type = _CardType.next;

  final MaintenanceModel? maintenance;
  final _CardType _type;

  bool get _isLast => _type == _CardType.last;

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMM yyyy', 'es').format(date);
  }

  String _formatKm(int? km) {
    if (km == null) return '—';
    return '${NumberFormat('#,###').format(km).replaceAll(',', '.')} km';
  }

  @override
  Widget build(BuildContext context) {
    final date = _isLast ? maintenance?.date : maintenance?.nextMaintenanceDate;
    final km = _isLast
        ? maintenance?.maintanceMileage
        : maintenance?.nextMaintenanceMileage;
    final iconColor = _isLast ? AppColors.info : AppColors.primary;
    final badgeText = _isLast
        ? context.l10n.maintenance_done
        : context.l10n.maintenance_legend_warning;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
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
            _formatDate(date),
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatKm(km),
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History CTA button ──────────────────────────────────────────────────────

class _HistoryButton extends StatelessWidget {
  const _HistoryButton({this.vehicleId});

  final String? vehicleId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(AppRoutes.maintenances, extra: vehicleId),
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
