import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEmptyGarageCard extends StatelessWidget {
  const HomeEmptyGarageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.darkBgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.two_wheeler,
              size: 28,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.home_emptyGarageTitle,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.home_emptyGarageSubtitle,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: context.l10n.home_emptyGarageCta,
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
