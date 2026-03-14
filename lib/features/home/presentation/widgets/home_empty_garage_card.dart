import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class HomeEmptyGarageCard extends StatelessWidget {
  const HomeEmptyGarageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.two_wheeler, size: 48, color: AppColors.darkBorder),
          const SizedBox(height: 8),
          const Text(
            HomeStrings.emptyGarage,
            style: TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            HomeStrings.emptyGarageDescription,
            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: HomeStrings.addVehicle,
            onPressed: () async {
              final result = await context.pushNamed(AppRoutes.createVehicle);
              if (context.mounted && result != null) {
                context.read<HomeCubit>().loadHomeData();
              }
            },
          ),
        ],
      ),
    );
  }
}
