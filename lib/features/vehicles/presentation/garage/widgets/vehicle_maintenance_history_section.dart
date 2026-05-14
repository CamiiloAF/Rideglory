import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.vehicle_maintenanceHistory,
                    style: context.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  AppTextButton(
                    label: context.l10n.vehicle_seeAll,
                    onPressed: () {
                      context.pushNamed(
                        AppRoutes.maintenances,
                        extra: vehicle.id,
                      );
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              AppSpacing.gapLg,
              BlocBuilder<
                VehicleMaintenancesCubit,
                ResultState<List<MaintenanceModel>>
              >(
                builder: (context, state) {
                  return state.when(
                    initial: () => const _LoadingState(),
                    loading: () => const _LoadingState(),
                    error: (error) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          context.l10n.maintenance_errorLoadingRecords,
                          style: context.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    empty: () => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            color: AppColors.darkTextSecondary,
                            size: 40,
                          ),
                          AppSpacing.gapMd,
                          Text(
                            context.l10n.maintenance_noRecordsYet,
                            style: context.bodyMedium?.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    data: (maintenances) {
                      // Show max 3 records
                      final items = maintenances.take(3).toList();

                      return Column(
                        children: items.map((maintenance) {
                          return _MaintenanceRecordCard(
                            maintenance: maintenance,
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MaintenanceRecordCard extends StatelessWidget {
  const _MaintenanceRecordCard({required this.maintenance});

  final MaintenanceModel maintenance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await context.pushNamed<dynamic>(
              AppRoutes.maintenanceDetail,
              extra: maintenance,
            );
            if (context.mounted && result != null) {
              if (result is MaintenanceModel) {
                context
                    .read<VehicleMaintenancesCubit>()
                    .updateMaintenanceLocally(result);
              } else if (result is Map && result['action'] == 'deleted') {
                context
                    .read<VehicleMaintenancesCubit>()
                    .deleteMaintenanceLocally(result['deletedId'] as String);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getMaintenanceIcon(maintenance.type),
                      color: context.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                AppSpacing.hGapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maintenance.name,
                        style: context.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        '${maintenance.date.formattedDate} • ${NumberFormat('#,###').format(maintenance.maintanceMileage)} km',
                        style: context.bodyMedium?.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapMd,
                Icon(Icons.chevron_right, color: AppColors.darkTextSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMaintenanceIcon(MaintenanceType type) {
    switch (type.name.toLowerCase()) {
      case 'oil':
      case 'oilchange':
        return Icons.oil_barrel_outlined;
      case 'chain':
        return Icons.link;
      case 'brakes':
        return Icons.sports_motorsports_outlined; // Placeholder flag/brakes
      case 'tires':
        return Icons.tire_repair_outlined;
      default:
        return Icons.build_outlined;
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.inline,
            ),
          ),
        ),
      ),
    );
  }
}
