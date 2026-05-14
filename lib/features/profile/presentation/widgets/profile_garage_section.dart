import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class ProfileGarageSection extends StatelessWidget {
  const ProfileGarageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, dynamic>(
      builder: (context, state) {
        final vehicleCubit = context.read<VehicleCubit>();
        final mainVehicle = vehicleCubit.currentVehicle;

        if (mainVehicle == null) {
          return _EmptyGarageCard(
            label: context.l10n.profile_noVehicle,
            onTap: () => context.pushNamed(AppRoutes.garage),
          );
        }

        return GestureDetector(
          onTap: () => context.pushNamed(AppRoutes.garage),
          child: Container(
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
                                color: AppColors.textOnDarkPrimary,
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
                              child: Text(
                                context.l10n.profile_mainVehicle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkBgPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (mainVehicle.licensePlate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          mainVehicle.licensePlate!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textOnDarkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textOnDarkTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyGarageCard extends StatelessWidget {
  const _EmptyGarageCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: AppColors.textOnDarkTertiary,
                size: 24,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.add,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
