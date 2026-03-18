import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEmptyGarageCard extends StatelessWidget {
  const HomeEmptyGarageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.two_wheeler, size: 48, color: context.colorScheme.outlineVariant),
          SizedBox(height: 8),
          Text(
            HomeStrings.emptyGarage,
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            HomeStrings.emptyGarageDescription,
            style: TextStyle(color: context.colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          SizedBox(height: 16),
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
