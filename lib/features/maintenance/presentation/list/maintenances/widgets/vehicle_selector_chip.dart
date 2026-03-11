import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/widgets/vehicle_selection_bottom_sheet.dart';

class VehicleSelectorChip extends StatelessWidget {
  final String? selectedVehicleId;
  final Function(String?) onVehicleSelected;

  const VehicleSelectorChip({
    super.key,
    required this.selectedVehicleId,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, state) {
        final availableVehicles = context
            .read<VehicleCubit>()
            .availableVehicles
            .where((v) => !v.isArchived)
            .toList();

        final hasSelection = selectedVehicleId != null;
        String label = MaintenanceStrings.allVehicles;
        if (hasSelection) {
          try {
            label = availableVehicles
                .firstWhere((v) => v.id == selectedVehicleId)
                .name;
          } catch (_) {}
        }

        return GestureDetector(
          onTap: () async {
            final result = await VehicleSelectionBottomSheet.show(
              context: context,
              vehicles: availableVehicles,
              selectedVehicleId: selectedVehicleId,
            );
            if (result != null) {
              // Toggle: tapping the selected vehicle deselects it
              final newId = result.id == selectedVehicleId ? null : result.id;
              onVehicleSelected(newId);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: hasSelection
                  ? AppColors.primary
                  : AppColors.darkSurfaceHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasSelection
                    ? AppColors.primaryDark
                    : AppColors.darkBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 16,
                  color: hasSelection ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.bodyMedium?.copyWith(
                    color: hasSelection ? Colors.white : Colors.white70,
                    fontWeight: hasSelection
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (hasSelection) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
