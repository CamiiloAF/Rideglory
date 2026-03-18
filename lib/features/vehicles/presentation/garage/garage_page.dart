import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_empty_state.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GaragePage extends StatefulWidget {
  const GaragePage({super.key});

  @override
  State<GaragePage> createState() => _GaragePageState();
}

class _GaragePageState extends State<GaragePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) context.goNamed(AppRoutes.home);
      },
      child: Scaffold(
          backgroundColor: const Color(
            0xFF1C1209,
          ), // Deeper contrast matching theme
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.two_wheeler, color: context.colorScheme.primary),
            ),
            title: Text(
              context.l10n.vehicle_myGarage,
              style: context.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_none,
                    color: context.colorScheme.primary,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<VehicleCubit, VehicleState>(
              builder: (context, state) {
                if (state is VehicleInitial) {
                  return Center(
                    child: CircularProgressIndicator(color: context.colorScheme.primary),
                  );
                }

                final List<VehicleModel> vehicles = context
                    .read<VehicleCubit>()
                    .availableVehicles
                    .where((v) => !v.isArchived)
                    .toList();

                if (vehicles.isEmpty) {
                  return const GarageEmptyState();
                }

                final totalVehicles = vehicles.length;
                final vehicleIndex = _currentIndex < totalVehicles
                    ? _currentIndex
                    : 0;
                final currentVehicle = vehicles[vehicleIndex];

                final totalMileage = vehicles.fold<int>(
                  0,
                  (sum, v) => sum + v.currentMileage,
                );

                final vehicleCubit = context.read<VehicleCubit>();
                final mainVehicleId = vehicleCubit.currentVehicle?.id;
                final canToggleMain = totalVehicles > 1;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Vehicle Image PageView
                      SizedBox(
                        height: 260,
                        child: PageView.builder(
                          itemCount: totalVehicles,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            final hasImage =
                                vehicle.imageUrl != null &&
                                vehicle.imageUrl!.isNotEmpty;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: const Color(0xFF2B2B2B), // Darker gray
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
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
                                    ? Center(
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

                      // Page Indicator Dots
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

                      SizedBox(height: 24),

                      // Detail View updates dynamically
                      VehicleDetailView(
                        vehicle: currentVehicle,
                        index: vehicleIndex,
                        totalVehicles: totalVehicles,
                        totalMileage: totalMileage,
                        onAddVehicle: () {
                          context.pushNamed(AppRoutes.createVehicle);
                        },
                        onOptionsTap: () {
                          GarageOptionsBottomSheet.show(
                            context,
                            currentVehicle,
                          );
                        },
                        isMainVehicle: currentVehicle.id != null &&
                            currentVehicle.id == mainVehicleId,
                        onMainVehicleChanged: canToggleMain &&
                                currentVehicle.id != null
                            ? (value) {
                                if (value) {
                                  vehicleCubit
                                      .setMainVehicle(currentVehicle.id!);
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
  }
}
