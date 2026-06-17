import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class GarageVehicleStatusBadge extends StatefulWidget {
  const GarageVehicleStatusBadge({super.key, required this.vehicle});

  final VehicleModel vehicle;

  // Cache keyed by vehicleId: survives widget recreation due to list rebuilds.
  static final Map<String, Future<int>> _futureCache = {};

  static void invalidate(String vehicleId) => _futureCache.remove(vehicleId);

  @override
  State<GarageVehicleStatusBadge> createState() =>
      _GarageVehicleStatusBadgeState();
}

class _GarageVehicleStatusBadgeState extends State<GarageVehicleStatusBadge> {
  Future<int>? _scheduledCountFuture;

  @override
  void initState() {
    super.initState();
    _resolveFuture();
  }

  @override
  void didUpdateWidget(GarageVehicleStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when the vehicle's archived status flips (active ↔ archived).
    if (oldWidget.vehicle.isArchived != widget.vehicle.isArchived ||
        oldWidget.vehicle.id != widget.vehicle.id) {
      GarageVehicleStatusBadge.invalidate(oldWidget.vehicle.id ?? '');
      setState(_resolveFuture);
    }
  }

  void _resolveFuture() {
    // Archived vehicles skip the API call entirely.
    if (widget.vehicle.isArchived) {
      _scheduledCountFuture = null;
      return;
    }
    final vehicleId = widget.vehicle.id;
    if (vehicleId == null) {
      _scheduledCountFuture = Future.value(0);
      return;
    }
    _scheduledCountFuture = GarageVehicleStatusBadge._futureCache.putIfAbsent(
      vehicleId,
      () {
        final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
        return useCase.execute(vehicleId).then(
          (result) => result.fold(
            (_) => 0,
            (page) => page.items
                .where((m) => m.mode == MaintenanceMode.scheduled)
                .length,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vehicle.isArchived) {
      return _badge(
        context,
        dotColor: AppColors.textOnDarkTertiary,
        bgColor: AppColors.darkTertiary,
        label: context.l10n.vehicle_statusArchived,
      );
    }

    return FutureBuilder<int>(
      future: _scheduledCountFuture,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final isUpToDate = count == 0;
        return _badge(
          context,
          dotColor: isUpToDate ? AppColors.statusGreen : AppColors.statusWarning,
          bgColor: isUpToDate
              ? AppColors.statusGreen.withValues(alpha: 0.13)
              : AppColors.statusWarning.withValues(alpha: 0.13),
          label: isUpToDate
              ? context.l10n.garage_upToDate
              : context.l10n.garage_upcomingCount(count),
        );
      },
    );
  }

  Widget _badge(
    BuildContext context, {
    required Color dotColor,
    required Color bgColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: dotColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
