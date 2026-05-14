import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class ProfileMainVehicleCard extends StatelessWidget {
  const ProfileMainVehicleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, dynamic>(
      builder: (context, state) {
        final vehicleCubit = context.read<VehicleCubit>();
        final mainVehicle = vehicleCubit.currentVehicle;

        if (mainVehicle == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.vehicle_myGarage.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDarkSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.darkBgSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.textOnDarkSecondary,
                      size: 24,
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mainVehicle.brand != null
                                    ? '${mainVehicle.brand} ${mainVehicle.name}'
                                    : mainVehicle.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (mainVehicle.isMainVehicle)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Principal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBgPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (mainVehicle.licensePlate != null)
                          Text(
                            mainVehicle.licensePlate!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textOnDarkSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
