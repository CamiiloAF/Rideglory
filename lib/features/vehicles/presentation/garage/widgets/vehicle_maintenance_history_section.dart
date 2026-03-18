import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/cubit/vehicle_maintenances_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';

class VehicleMaintenanceHistorySection extends StatelessWidget {
  const VehicleMaintenanceHistorySection({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(vehicle.id),
      create: (context) =>
          getIt<VehicleMaintenancesCubit>()..fetchMaintenances(vehicle.id!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                VehicleStrings.maintenanceHistory,
                style: context.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(AppRoutes.maintenances, extra: vehicle.id);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  VehicleStrings.seeAll,
                  style: context.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    color: const Color(0xFF2C241E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      MaintenanceStrings.errorLoadingRecords,
                      style: context.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                empty: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.history, color: Colors.grey[600], size: 40),
                      const SizedBox(height: 12),
                      Text(
                        MaintenanceStrings.noRecordsYet,
                        style: context.bodyMedium?.copyWith(
                          color: Colors.grey[400],
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
                      return _MaintenanceRecordCard(maintenance: maintenance);
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
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
        color: const Color(
          0xFF262628,
        ), // Matches dark surface in the design screenshot slightly
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
                    color: const Color(
                      0xFF332A24,
                    ), // Background for icon matching mockup
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getMaintenanceIcon(maintenance.type),
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd \'de\' MMM, yyyy').format(maintenance.date)} • ${NumberFormat('#,###').format(maintenance.maintanceMileage)} km',
                        style: context.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: Colors.grey[500]),
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
            color: const Color(0xFF262628),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
