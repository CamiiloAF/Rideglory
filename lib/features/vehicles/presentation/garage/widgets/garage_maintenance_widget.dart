import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_maintenance_card.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_section_header.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_view_history_button.dart';

typedef GarageMaintenanceSummary = ({
  MaintenanceModel? last,
  MaintenanceModel? next,
});

class GarageMaintenanceWidget extends StatefulWidget {
  const GarageMaintenanceWidget({
    super.key,
    required this.vehicle,
    required this.onViewHistoryTap,
  });

  final VehicleModel vehicle;
  final VoidCallback onViewHistoryTap;

  @override
  State<GarageMaintenanceWidget> createState() =>
      _GarageMaintenanceWidgetState();
}

class _GarageMaintenanceWidgetState extends State<GarageMaintenanceWidget> {
  late Future<GarageMaintenanceSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary(widget.vehicle.id);
  }

  @override
  void didUpdateWidget(GarageMaintenanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.id != widget.vehicle.id) {
      setState(() {
        _summaryFuture = _loadSummary(widget.vehicle.id);
      });
    }
  }

  Future<GarageMaintenanceSummary> _loadSummary(String? vehicleId) async {
    if (vehicleId == null) return (last: null, next: null);

    final useCase = getIt<GetMaintenancesByVehicleIdUseCase>();
    final result = await useCase.execute(vehicleId);

    return result.fold((_) => (last: null, next: null), (page) {
      final completed =
          page.items.where((m) => m.mode == MaintenanceMode.completed).toList()
            ..sort((a, b) {
              final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
              final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
              return dateB.compareTo(dateA);
            });

      final scheduled =
          page.items.where((m) => m.mode == MaintenanceMode.scheduled).toList()
            ..sort((a, b) {
              if (a.nextDate != null && b.nextDate != null) {
                return a.nextDate!.compareTo(b.nextDate!);
              }
              if (a.nextDate != null) return -1;
              if (b.nextDate != null) return 1;
              return (a.nextOdometer ?? 0).compareTo(b.nextOdometer ?? 0);
            });

      return (last: completed.firstOrNull, next: scheduled.firstOrNull);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GarageSectionHeader(
          label: context.l10n.maintenance_maintenances.toUpperCase(),
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        FutureBuilder<GarageMaintenanceSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            final last = snapshot.data?.last;
            final next = snapshot.data?.next;
            final isOverdue =
                next != null &&
                MaintenanceModel.calculateStatus(
                      next,
                      widget.vehicle.currentMileage,
                    ) ==
                    MaintenanceStatus.overdue;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GarageMaintenanceCard(
                        isNext: false,
                        maintenance: last,
                        vehicle: widget.vehicle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GarageMaintenanceCard(
                        isNext: true,
                        maintenance: next,
                        vehicle: widget.vehicle,
                        isOverdue: isOverdue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GarageViewHistoryButton(onTap: widget.onViewHistoryTap),
              ],
            );
          },
        ),
      ],
    );
  }
}
