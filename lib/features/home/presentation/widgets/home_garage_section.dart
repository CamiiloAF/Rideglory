import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_card.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class HomeGarageSection extends StatelessWidget {
  const HomeGarageSection({super.key, this.vehicle});

  final VehicleModel? vehicle;

  @override
  Widget build(BuildContext context) {
    final vehicleFromCubit = context.watch<VehicleCubit>().currentVehicle;
    final effectiveVehicle = vehicleFromCubit ?? vehicle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                HomeStrings.myGarage,
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => context.goNamed(AppRoutes.garage),
                child: Text(
                  'VER TODO',
                  style: TextStyle(
                    color: context.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          effectiveVehicle != null
              ? HomeGarageCard(vehicle: effectiveVehicle)
              : const HomeEmptyGarageCard(),
        ],
      ),
    );
  }
}
