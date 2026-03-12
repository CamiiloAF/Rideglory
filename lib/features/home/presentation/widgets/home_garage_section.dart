import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_card.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class HomeGarageSection extends StatelessWidget {
  const HomeGarageSection({super.key, this.vehicle});

  final VehicleModel? vehicle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                HomeStrings.myGarage,
                style: TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.goNamed(AppRoutes.garage),
                child: const Text(
                  'VER TODAS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          vehicle != null
              ? HomeGarageCard(vehicle: vehicle!)
              : const HomeEmptyGarageCard(),
        ],
      ),
    );
  }
}
