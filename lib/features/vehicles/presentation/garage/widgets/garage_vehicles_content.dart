import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_empty_state.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class GarageVehiclesContent extends StatelessWidget {
  const GarageVehiclesContent({
    super.key,
    required this.pageController,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onGarageListUpdatedLocally,
  });

  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  /// Sync carousel index after VehicleCubit was updated locally (no API refetch).
  final void Function([VehicleModel? focusVehicle]) onGarageListUpdatedLocally;

  @override
  Widget build(BuildContext context) {
    final vehicles = context.read<VehicleCubit>().availableVehicles.where((v) {
      return !v.isArchived;
    }).toList();

    if (vehicles.isEmpty) {
      return GarageEmptyState(
        onVehicleSavedLocally: onGarageListUpdatedLocally,
      );
    }

    final totalVehicles = vehicles.length;
    final vehicleIndex = currentIndex < totalVehicles ? currentIndex : 0;
    final currentVehicle = vehicles[vehicleIndex];

    final totalMileage = vehicles.fold<int>(
      0,
      (sum, v) => sum + v.currentMileage,
    );

    final vehicleCubit = context.read<VehicleCubit>();
    final canToggleMain = totalVehicles > 1;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: PageView.builder(
              controller: pageController,
              itemCount: totalVehicles,
              onPageChanged: onIndexChanged,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final hasImage =
                    vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: AppColors.darkBackground,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      image: hasImage
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                vehicle.imageUrl!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasImage
                        ? const Center(
                            child: Icon(
                              Icons.motorcycle,
                              size: 80,
                              color: Colors.white24,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalVehicles,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == vehicleIndex ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: i == vehicleIndex
                      ? context.colorScheme.primary
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          AppSpacing.gapXxl,
          VehicleDetailView(
            vehicle: currentVehicle,
            index: vehicleIndex,
            totalVehicles: totalVehicles,
            totalMileage: totalMileage,
            onAddVehicle: () async {
              final result = await context.pushNamed(AppRoutes.createVehicle);
              if (!context.mounted || result == null) return;
              onGarageListUpdatedLocally(
                result is VehicleModel ? result : null,
              );
            },
            onOptionsTap: () {
              GarageOptionsBottomSheet.show(
                context,
                currentVehicle,
                onGarageListUpdatedLocally: onGarageListUpdatedLocally,
              );
            },
            isMainVehicle: currentVehicle.isMainVehicle,
            onMainVehicleChanged: canToggleMain && currentVehicle.id != null
                ? (value) {
                    if (value) {
                      vehicleCubit.setMainVehicle(currentVehicle.id!);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
