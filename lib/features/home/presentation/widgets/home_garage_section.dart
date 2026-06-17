import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_section_header.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class HomeGarageSection extends StatelessWidget {
  const HomeGarageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: context.l10n.home_sectionGarage,
            onViewAll: () => context.go(AppRoutes.garage),
            viewAllLabel: context.l10n.home_viewAllLink,
          ),
          const SizedBox(height: 12),
          BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
            builder: (context, vehicleState) {
              return vehicleState.when(
                initial: () => _GaragePlaceholder(),
                loading: () => _GaragePlaceholder(),
                data: (vehicles) {
                  if (vehicles.isEmpty) return const HomeEmptyGarageCard();
                  final mainVehicle =
                      vehicles.where((v) => v.isMainVehicle).firstOrNull ??
                          vehicles.first;
                  return HomeGarageCard(vehicle: mainVehicle);
                },
                empty: () => const HomeEmptyGarageCard(),
                error: (_) => const HomeEmptyGarageCard(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GaragePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
