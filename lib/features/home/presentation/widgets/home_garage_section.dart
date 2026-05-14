import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_card.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeGarageSection extends StatelessWidget {
  const HomeGarageSection({super.key, this.vehicle});

  final VehicleModel? vehicle;

  @override
  Widget build(BuildContext context) {
    final vehicleState = context.watch<VehicleCubit>().state;
    final mainVehicle = vehicleState is Data<List<VehicleModel>>
        ? (vehicleState.data.where((v) => v.isMainVehicle).firstOrNull ??
            vehicleState.data.firstOrNull)
        : vehicle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: context.l10n.home_sectionGarage,
            onViewAll: () => context.go(AppRoutes.garage),
            viewAllLabel: context.l10n.home_viewAllLink,
          ),
          const SizedBox(height: 12),
          mainVehicle != null
              ? HomeGarageCard(vehicle: mainVehicle)
              : const HomeEmptyGarageCard(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onViewAll,
    required this.viewAllLabel,
  });

  final String title;
  final VoidCallback onViewAll;
  final String viewAllLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            viewAllLabel.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
