import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_summary_header.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/vehicle_selector_chip.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MaintenancesHeaderView extends StatelessWidget {
  final Future<void> Function() onFilterPressed;
  final int activeFilterCount;
  final Function(String) onSearchChanged;
  final List<MaintenanceModel> maintenances;

  const MaintenancesHeaderView({
    super.key,
    required this.onFilterPressed,
    required this.activeFilterCount,
    required this.onSearchChanged,
    required this.maintenances,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: context.bodyMedium?.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.l10n.maintenance_searchMaintenances,
                hintStyle: context.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(Icons.search, color: context.colorScheme.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        BlocBuilder<MaintenancesCubit, ResultState<List<MaintenanceModel>>>(
          builder: (context, state) {
            final cubit = context.read<MaintenancesCubit>();
            final filters = cubit.filters;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VehicleSelectorChip(
                selectedVehicleId: filters.vehicleIds.isNotEmpty
                    ? filters.vehicleIds.first
                    : null,
                onVehicleSelected: (String? vehicleId) {
                  final updatedIds = vehicleId != null
                      ? [vehicleId]
                      : <String>[];
                  cubit.updateFilters(filters.copyWith(vehicleIds: updatedIds));
                },
              ),
            );
          },
        ),

        MaintenancesSummaryHeader(maintenances: maintenances),
      ],
    );
  }
}
